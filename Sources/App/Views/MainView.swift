import SwiftUI

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