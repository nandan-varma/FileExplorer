import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        Group {
            switch viewModel.viewMode {
            case .list:
                ListView(viewModel: viewModel)
            case .icon:
                IconView(viewModel: viewModel)
            case .column:
                ColumnView(viewModel: viewModel)
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