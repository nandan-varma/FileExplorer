import SwiftUI
import Foundation

struct SidebarView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    let standardDirectories: [FileItem] = {
        let directories: [FileManager.SearchPathDirectory] = [.documentDirectory, .downloadsDirectory, .desktopDirectory]
        let urls = directories.flatMap { FileManager.default.urls(for: $0, in: .userDomainMask) }
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) ?? []
        let volumeItems = volumes.map(FileItem.init)
        return urls.map(FileItem.init) + volumeItems
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