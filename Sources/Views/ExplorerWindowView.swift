import SwiftUI

struct ExplorerWindowView: View {
    @StateObject var viewModel = ExplorerViewModel()
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SidebarView(viewModel: viewModel)
                ContentAreaView(viewModel: viewModel)
            }
            StatusBarView(viewModel: viewModel)
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack {
                    Spacer()
                    Text(viewModel.selectedSidebarItem.label)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
                .frame(width: 180)
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    Button(action: { viewModel.goBack() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(viewModel.canGoBack ? .white : .gray)
                    }
                    .disabled(!viewModel.canGoBack)
                    Button(action: { viewModel.goForward() }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(viewModel.canGoForward ? .white : .gray)
                    }
                    .disabled(!viewModel.canGoForward)
                    Button(action: { viewModel.quickLook() }) {
                        Image(systemName: "play.circle")
                    }
                    Button(action: { viewModel.newTab() }) {
                        Image(systemName: "square.on.square")
                    }
                    Button(action: { viewModel.openVSCode() }) {
                        Image(systemName: "chevron.left.slash.chevron.right")
                    }
                    Button(action: { viewModel.trash() }) {
                        Image(systemName: "trash")
                    }
                    .disabled(true)
                    Button(action: { viewModel.share() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: { viewModel.viewOptions() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    Button(action: { viewModel.toggleViewMode() }) {
                        Image(systemName: "rectangle.grid.1x2")
                    }
                    Button(action: { viewModel.moreOptions() }) {
                        Image(systemName: "ellipsis")
                    }
                    Spacer(minLength: 12)
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .frame(minWidth: 120, maxWidth: .infinity)
                    }
                    .padding(6)
                    .background(Color.white.opacity(0.10))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// WindowAccessor to get NSWindow for customization
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    ExplorerWindowView()
}
