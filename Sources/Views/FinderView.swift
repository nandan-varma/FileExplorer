import SwiftUI

struct FinderView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            MainFileAreaView(viewModel: viewModel)
        }
    }
}