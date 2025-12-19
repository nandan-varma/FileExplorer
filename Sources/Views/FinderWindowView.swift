import SwiftUI

struct FinderWindowView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            TitleBarView(viewModel: viewModel)
            NavigationSplitView {
                SidebarView(viewModel: viewModel)
            } detail: {
                MainFileAreaView(viewModel: viewModel)
            }
            StatusBarView(viewModel: viewModel)
        }
        .preferredColorScheme(.dark)
        .background(.ultraThinMaterial)
    }
}