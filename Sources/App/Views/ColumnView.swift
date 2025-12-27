import SwiftUI

struct ColumnView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        List(viewModel.filteredItems) { item in
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
                Button("Get Info") { NSWorkspace.shared.selectFile(item.url.path, inFileViewerRootedAtPath: item.url.deletingLastPathComponent().path) }
                Button("Quick Look") { /* TODO */ }
                Button("Compress") { /* TODO */ }
                Button("Tags") { /* TODO */ }
            }
        }
    }
}