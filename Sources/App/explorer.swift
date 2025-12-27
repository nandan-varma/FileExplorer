import SwiftUI
import SwiftUI
import AppKit
import QuickLook

// MARK: - Models
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    let size: Int64?
    let modifiedDate: Date?
    let isDirectory: Bool
    var fileExtension: String { url.pathExtension }

    init(url: URL) {
        self.url = url
        self.isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        if let fileSize = values?.fileSize {
            self.size = Int64(fileSize)
        } else {
            self.size = nil
        }
        self.modifiedDate = values?.contentModificationDate
    }
}

// MARK: - Services
protocol FileService {
    func listContents(of directory: URL) throws -> [FileItem]
    func createFile(at url: URL, name: String) throws -> FileItem
    func createDirectory(at url: URL, name: String) throws -> FileItem
    func deleteFile(at url: URL) throws
    func moveFile(from: URL, to: URL) throws
}

struct FileManagerService: FileService {
    func listContents(of directory: URL) throws -> [FileItem] {
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: .skipsHiddenFiles)
        return contents.map(FileItem.init)
    }

    func createFile(at url: URL, name: String) throws -> FileItem {
        let fileURL = url.appendingPathComponent(name)
        try Data().write(to: fileURL)
        return FileItem(url: fileURL)
    }

    func createDirectory(at url: URL, name: String) throws -> FileItem {
        let dirURL = url.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: false)
        return FileItem(url: dirURL)
    }

    func deleteFile(at url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    func moveFile(from: URL, to: URL) throws {
        try FileManager.default.moveItem(at: from, to: to)
    }
}

// MARK: - ViewModels
enum ViewMode { case list, icon }

class FileExplorerViewModel: ObservableObject {
    @Published var currentDirectory: FileItem?
    @Published var items: [FileItem] = []
    @Published var searchQuery = ""
    @Published var viewMode: ViewMode = .list
    @Published var selectedItemIDs: Set<FileItem.ID> = []

    private let fileService: FileService
    private var navigationStack: [FileItem] = []
    private var currentIndex = -1

    init(fileService: FileService = FileManagerService()) {
        self.fileService = fileService
        if let home = FileManager.default.urls(for: .userDirectory, in: .userDomainMask).first {
            navigateToDirectory(FileItem(url: home))
        }
    }

    var filteredItems: [FileItem] {
        if searchQuery.isEmpty {
            return items
        }
        return items.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
    }

    var canGoBack: Bool { currentIndex > 0 }
    var canGoForward: Bool { currentIndex < navigationStack.count - 1 }

    var selectedItems: [FileItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    func navigateToDirectory(_ item: FileItem) {
        guard item.isDirectory else { return }
        currentDirectory = item
        do {
            items = try fileService.listContents(of: item.url)
            navigationStack = Array(navigationStack.prefix(currentIndex + 1))
            navigationStack.append(item)
            currentIndex = navigationStack.count - 1
            selectedItemIDs.removeAll()
        } catch {
            print("Error listing contents: \(error)")
        }
    }

    func goBack() {
        guard canGoBack else { return }
        currentIndex -= 1
        navigateToDirectory(navigationStack[currentIndex])
    }

    func goForward() {
        guard canGoForward else { return }
        currentIndex += 1
        navigateToDirectory(navigationStack[currentIndex])
    }

    func createFile(name: String) {
        guard let dir = currentDirectory else { return }
        do {
            let item = try fileService.createFile(at: dir.url, name: name)
            items.append(item)
        } catch {
            print("Error creating file: \(error)")
        }
    }

    func createDirectory(name: String) {
        guard let dir = currentDirectory else { return }
        do {
            let item = try fileService.createDirectory(at: dir.url, name: name)
            items.append(item)
        } catch {
            print("Error creating directory: \(error)")
        }
    }

    func deleteItems(_ itemsToDelete: [FileItem]) {
        for item in itemsToDelete {
            do {
                try fileService.deleteFile(at: item.url)
                items.removeAll { $0.id == item.id }
            } catch {
                print("Error deleting \(item.name): \(error)")
            }
        }
        selectedItemIDs.removeAll()
    }

    func renameItem(_ item: FileItem, to newName: String) {
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileService.moveFile(from: item.url, to: newURL)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = FileItem(url: newURL)
            }
        } catch {
            print("Error renaming: \(error)")
        }
    }

    func handleDrop(_ urls: [URL]) {
        guard let destDir = currentDirectory?.url else { return }
        for url in urls {
            let destURL = destDir.appendingPathComponent(url.lastPathComponent)
            do {
                try fileService.moveFile(from: url, to: destURL)
            } catch {
                print("Error moving \(url): \(error)")
            }
        }
        navigateToDirectory(currentDirectory!)
    }
}

// MARK: - Views
struct MainView: View {
    @StateObject private var viewModel = FileExplorerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(viewModel: viewModel)
            HStack(spacing: 0) {
                SidebarView(viewModel: viewModel)
                ContentView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct ToolbarView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        HStack {
            Button(action: viewModel.goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.canGoBack)

            Button(action: viewModel.goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.canGoForward)

            Picker("View Mode", selection: $viewModel.viewMode) {
                Text("List").tag(ViewMode.list)
                Text("Icon").tag(ViewMode.icon)
            }
            .pickerStyle(.segmented)

            TextField("Search", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)

            Spacer()

            if let dir = viewModel.currentDirectory {
                Text(dir.name)
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    let standardDirectories: [FileItem] = {
        let directories: [FileManager.SearchPathDirectory] = [.documentDirectory, .downloadsDirectory, .desktopDirectory]
        let urls = directories.flatMap { FileManager.default.urls(for: $0, in: .userDomainMask) }
        return urls.map(FileItem.init)
    }()

    var body: some View {
        List(standardDirectories) { item in
            Button(action: { viewModel.navigateToDirectory(item) }) {
                Label(item.name, systemImage: "folder")
            }
            .buttonStyle(.plain)
        }
        .frame(width: 200)
        .listStyle(.sidebar)
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        Group {
            switch viewModel.viewMode {
            case .list:
                ListView(viewModel: viewModel)
            case .icon:
                IconView(viewModel: viewModel)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: "public.file-url") { (urlData, error) in
                if let urlData = urlData as? Data,
                   let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                    urls.append(url)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            viewModel.handleDrop(urls)
        }
    }
}

struct ListView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @State private var selection = Set<FileItem.ID>()
    @State private var quickLookURL: URL?

    var body: some View {
        List(viewModel.filteredItems, selection: $selection) { item in
            HStack {
                Image(systemName: item.isDirectory ? "folder" : "doc")
                VStack(alignment: .leading) {
                    Text(item.name)
                    HStack {
                        Text("Size: \(item.size.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "--")")
                        Text("Modified: \(item.modifiedDate?.formatted() ?? "--")")
                        Text("Kind: \(item.fileExtension.isEmpty ? "Folder" : item.fileExtension.uppercased())")
                    }
                    .font(.caption)
                }
            }
            .onTapGesture(count: 2) {
                if item.isDirectory {
                    viewModel.navigateToDirectory(item)
                } else {
                    NSWorkspace.shared.open(item.url)
                }
            }
            .contextMenu {
                Button("Get Info") { openGetInfo(for: item) }
                Button("Quick Look") { quickLookURL = item.url }
                Button("Compress") { compressItem(item) }
                Button("Tags") { openTags(for: item) }
            }
            .onDrag { NSItemProvider(object: item.url as NSURL) }
        }
        .quickLookPreview($quickLookURL)
        .onKeyPress(.space) {
            if let selected = selection.first, let item = viewModel.filteredItems.first(where: { $0.id == selected }) {
                quickLookURL = item.url
            }
            return .handled
        }
        .onDeleteCommand {
            viewModel.deleteItems(viewModel.filteredItems.filter { selection.contains($0.id) })
        }
    }

    private func openGetInfo(for item: FileItem) {
        NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path)
    }

    private func compressItem(_ item: FileItem) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        task.arguments = ["-c", "-k", "--sequesterRsrc", item.url.path, (item.url.path + ".zip")]
        try? task.run()
    }

    private func openTags(for item: FileItem) {
        NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path)
    }
}

struct IconView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @State private var quickLookURL: URL?

    let columns = [GridItem(.adaptive(minimum: 80))]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.filteredItems) { item in
                    VStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                            .resizable()
                            .frame(width: 64, height: 64)
                        Text(item.name)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .onTapGesture(count: 2) {
                        if item.isDirectory {
                            viewModel.navigateToDirectory(item)
                        } else {
                            NSWorkspace.shared.open(item.url)
                        }
                    }
                    .contextMenu {
                        Button("Get Info") { NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path) }
                        Button("Quick Look") { quickLookURL = item.url }
                        Button("Compress") { compressItem(item) }
                        Button("Tags") { openTags(for: item) }
                    }
                    .onDrag { NSItemProvider(object: item.url as NSURL) }
                }
            }
            .padding()
        }
        .quickLookPreview($quickLookURL)
    }

    private func compressItem(_ item: FileItem) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        task.arguments = ["-c", "-k", "--sequesterRsrc", item.url.path, (item.url.path + ".zip")]
        try? task.run()
    }

    private func openTags(for item: FileItem) {
        NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path)
    }
}

// MARK: - App
@main
struct ExplorerApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}