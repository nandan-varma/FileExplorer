import SwiftUI

struct ExplorerWindowView: View {
    @StateObject var viewModel = ExplorerViewModel()
    @State private var window: NSWindow?
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SidebarView(viewModel: viewModel)
                ContentAreaView(viewModel: viewModel)
            }
            StatusBarView(viewModel: viewModel)
            WindowAccessor(window: $window)
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .padding(24)
        .onChange(of: window) { old, new in
            guard let new else { return }
            new.titlebarAppearsTransparent = true
            new.isOpaque = false
            new.backgroundColor = .clear
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.selectedSidebarItem.label)
                    .font(.system(size: 16, weight: .semibold, design: .default))
            }
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.canGoBack)
                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .disabled(!viewModel.canGoForward)
            }
            ToolbarItemGroup(placement: .automatic) {
                ToolbarIconButton(systemName: "play.circle", tooltip: "Quick Look") { viewModel.quickLook() }
                ToolbarIconButton(systemName: "square.on.square", tooltip: "New Tab") { viewModel.newTab() }
                ToolbarIconButton(systemName: "chevron.left.slash.chevron.right", tooltip: "VS Code") { viewModel.openVSCode() }
                ToolbarIconButton(systemName: "trash", tooltip: "Trash", disabled: true) { viewModel.trash() }
                ToolbarIconButton(systemName: "square.and.arrow.up", tooltip: "Share") { viewModel.share() }
                ToolbarIconButton(systemName: "line.3.horizontal.decrease.circle", tooltip: "View Options") { viewModel.viewOptions() }
                ToolbarIconButton(systemName: "rectangle.grid.1x2", tooltip: "Grid/List Toggle") { viewModel.toggleViewMode() }
                ToolbarIconButton(systemName: "ellipsis", tooltip: "More") { viewModel.moreOptions() }
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 120)
                }
                .padding(6)
                .background(Color.white.opacity(0.10))
                .cornerRadius(8)
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

// ToolbarIconButton for toolbar actions
struct ToolbarIconButton: View {
    let systemName: String
    let tooltip: String
    var disabled: Bool = false
    var action: () -> Void
    @State private var hovering = false
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(disabled ? .gray : .white)
                .frame(width: 28, height: 28)
                .background(hovering ? Color.white.opacity(0.18) : Color.white.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.borderless)
        .disabled(disabled)
        .onHover { hovering in self.hovering = hovering }
        .help(tooltip)
    }
}

#Preview {
    ExplorerWindowView()
}
