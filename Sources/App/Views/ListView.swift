import SwiftUI
import AppKit
import QuickLook

struct ListView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @State private var selection = Set<FileItem.ID>()
    @State private var sortOrder = [KeyPathComparator(\FileItem.name)]
    @State private var quickLookURL: URL?
    @State private var showRename = false
    @State private var itemToRename: FileItem?
    @State private var renameName = ""

    var sortedItems: [FileItem] {
        viewModel.sortedItems(using: sortOrder)
    }

    var body: some View {
        Table(sortedItems, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { item in
                HStack {
                    Image(systemName: item.isDirectory ? "folder" : "doc")
                    Text(item.name)
                }
                .onTapGesture(count: 2) {
                    if item.isDirectory {
                        viewModel.navigateToDirectory(item)
                    } else {
                        NSWorkspace.shared.open(item.url)
                    }
                }
                .contextMenu {
                    Button("Rename") {
                        itemToRename = item
                        renameName = item.name
                        showRename = true
                    }
                    Button("Get Info") { openGetInfo(for: item) }
                    Button("Quick Look") { quickLookURL = item.url }
                    Button("Compress") { compressItem(item) }
                    Button("Tags") { openTags(for: item) }
                }
            }
            TableColumn("Size") { item in
                Text(item.size.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) } ?? "--")
            }
            TableColumn("Created") { item in
                Text(item.creationDate?.formatted() ?? "--")
            }
            TableColumn("Modified") { item in
                Text(item.modifiedDate?.formatted() ?? "--")
            }
            TableColumn("Kind") { item in
                Text(item.fileExtension.isEmpty ? "Folder" : item.fileExtension.uppercased())
            }
        }
        .quickLookPreview($quickLookURL)
        .onKeyPress(.space) {
            if let selected = selection.first, let item = sortedItems.first(where: { $0.id == selected }) {
                quickLookURL = item.url
            }
            return .handled
        }
        .onDeleteCommand {
            viewModel.deleteItems(sortedItems.filter { selection.contains($0.id) })
        }
        .sheet(isPresented: $showRename) {
            if let item = itemToRename {
                RenameDialog(name: $renameName, onRename: {
                    viewModel.renameItem(item, to: renameName)
                    showRename = false
                }, onCancel: { showRename = false })
            }
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

struct RenameDialog: View {
    @Binding var name: String
    let onRename: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Text("Rename")
            TextField("New Name", text: $name)
            HStack {
                Button("Cancel", action: onCancel)
                Button("Rename", action: onRename)
                    .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}