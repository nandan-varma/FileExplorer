import Foundation
import SwiftUI

class ExplorerViewModel: ObservableObject {

        // Toolbar actions (stubs)
        func quickLook() { /* TODO: Implement Quick Look */ }
        func newTab() { /* TODO: Implement New Tab */ }
        func openVSCode() { /* TODO: Implement VS Code integration */ }
        func trash() { /* TODO: Implement Trash */ }
        func share() { /* TODO: Implement Share */ }
        func viewOptions() { /* TODO: Implement View Options */ }
        func toggleViewMode() { /* TODO: Implement Grid/List toggle */ }
        func moreOptions() { /* TODO: Implement More Options */ }
    // Sidebar
    @Published var selectedSidebarItem: SidebarItemType = .downloads
    @Published var sidebarItems: [SidebarItemType] = SidebarItemType.allCases
    
    // Navigation
    @Published var navigationStack: [SidebarItemType] = [.downloads]
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    private var forwardStack: [SidebarItemType] = []
    
    // File list
    @Published var files: [FileItem] = []
    @Published var currentFolderURL: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var selectedFile: FileItem.ID? = nil
    @Published var sortColumn: FileSortColumn = .dateAdded
    @Published var sortAscending: Bool = false
    
    // Search
    @Published var searchText: String = ""
    
    // Breadcrumb
    @Published var breadcrumb: [String] = ["Macintosh HD", "Users", "nandan", "Downloads"]
    
    // MARK: - Sidebar
    func selectSidebarItem(_ item: SidebarItemType) {
        selectedSidebarItem = item
        navigationStack.append(item)
        forwardStack.removeAll()
        updateNavigationState()
        // Update files for selected item
        let url = urlForSidebarItem(item)
        currentFolderURL = url
        loadFiles(at: url)
    }

    private func urlForSidebarItem(_ item: SidebarItemType) -> URL {
        let fm = FileManager.default
        switch item {
        case .downloads:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        case .documents:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        case .desktop:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        case .pictures:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
        case .applications:
            return URL(fileURLWithPath: "/Applications")
        case .icloud:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents")
        case .home, .nandan:
            return fm.homeDirectoryForCurrentUser
        case .dev:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("dev")
        case .macbook:
            return URL(fileURLWithPath: "/")
        case .recents, .shared:
            return fm.homeDirectoryForCurrentUser // fallback
        }
    }

    func loadFiles(at url: URL) {
        let fm = FileManager.default
        do {
            let contents = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles])
            self.files = contents.map { fileURL in
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                let isFolder = resourceValues?.isDirectory ?? false
                let size = isFolder ? nil : (resourceValues?.fileSize).flatMap { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) }
                let kind = isFolder ? "Folder" : fileURL.pathExtension.uppercased()
                let dateAdded = resourceValues?.contentModificationDate.map { Self.dateFormatter.string(from: $0) }
                return FileItem(
                    name: fileURL.lastPathComponent,
                    size: size,
                    kind: kind,
                    dateAdded: dateAdded,
                    isFolder: isFolder,
                    expanded: false
                )
            }.sorted { $0.name.lowercased() < $1.name.lowercased() }
        } catch {
            self.files = []
        }
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // Load files for initial folder on init
    init() {
        loadFiles(at: currentFolderURL)
    }
    
    // MARK: - Navigation
    func goBack() {
        guard navigationStack.count > 1 else { return }
        let last = navigationStack.removeLast()
        forwardStack.append(last)
        selectedSidebarItem = navigationStack.last ?? .downloads
        updateNavigationState()
        // TODO: Update files for selected item
    }
    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        navigationStack.append(next)
        selectedSidebarItem = next
        updateNavigationState()
        // TODO: Update files for selected item
    }
    private func updateNavigationState() {
        canGoBack = navigationStack.count > 1
        canGoForward = !forwardStack.isEmpty
    }
    
    // MARK: - File Selection
    func selectFile(_ file: FileItem) {
        selectedFile = file.id
    }
    
    // MARK: - Sorting
    func sort(by column: FileSortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
        // TODO: Sort files
    }
    
    // MARK: - Search
    func updateSearch(_ text: String) {
        searchText = text
        // TODO: Filter files
    }
    
    // MARK: - Breadcrumb
    func navigateToBreadcrumb(index: Int) {
        breadcrumb = Array(breadcrumb.prefix(index + 1))
        // TODO: Update files for breadcrumb
    }
}

// Sidebar item types
enum SidebarItemType: String, CaseIterable, Identifiable {
    case applications, documents, desktop, downloads, pictures, recents, shared, nandan, dev, icloud, home, macbook
    var id: String { rawValue }
    var label: String {
        switch self {
        case .applications: return "Applications"
        case .documents: return "Documents"
        case .desktop: return "Desktop"
        case .downloads: return "Downloads"
        case .pictures: return "Pictures"
        case .recents: return "Recents"
        case .shared: return "Shared"
        case .nandan: return "nandan"
        case .dev: return "dev"
        case .icloud: return "iCloud Drive"
        case .home: return "nandan"
        case .macbook: return "Nandan’s MacBook Air"
        }
    }
}

enum FileSortColumn {
    case name, size, kind, dateAdded
}
