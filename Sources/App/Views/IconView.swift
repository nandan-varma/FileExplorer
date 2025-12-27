import SwiftUI
import AppKit
import QuickLook

struct IconView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @State private var quickLookURL: URL?
    @State private var selectedItem: FileItem?
    @State private var showRename = false
    @State private var renameName = ""

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
                    .background(selectedItem?.id == item.id ? Color.blue.opacity(0.3) : Color.clear)
                    .onTapGesture(count: 1) {
                        selectedItem = item
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
                            selectedItem = item
                            renameName = item.name
                            showRename = true
                        }
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
        .onKeyPress(.space) {
            if let item = selectedItem {
                quickLookURL = item.url
            }
            return .handled
        }
        .focusable()
        .sheet(isPresented: $showRename) {
            if let item = selectedItem {
                RenameDialog(name: $renameName, onRename: {
                    viewModel.renameItem(item, to: renameName)
                    showRename = false
                }, onCancel: { showRename = false })
            }
        }
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