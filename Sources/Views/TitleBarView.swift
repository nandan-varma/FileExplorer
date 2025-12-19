import SwiftUI

struct TitleBarView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        HStack(spacing: 8) {
            // Navigation Arrows
            Button(action: {
                viewModel.goToParentDirectory()
            }) {
                Image(systemName: "arrow.left.circle")
                    .foregroundColor(canGoBack ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)

            Button(action: {
                // Forward not implemented yet, placeholder
            }) {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.secondary) // Always disabled for now
            }
            .buttonStyle(.plain)
            .disabled(true)

            Spacer()

            // Title
            Text(viewModel.currentDirectory.lastPathComponent)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // Toolbar Icons
            HStack(spacing: 8) {
                Button(action: { /* QuickLook placeholder */ }) {
                    Image(systemName: "play.circle")
                }
                .buttonStyle(.plain)

                Button(action: { /* New tab placeholder */ }) {
                    Image(systemName: "plus.square")
                }
                .buttonStyle(.plain)

                Button(action: { /* VS Code placeholder */ }) {
                    Image(systemName: "chevron.left.slash.chevron.right") // Placeholder
                }
                .buttonStyle(.plain)

                Button(action: { /* Trash placeholder */ }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(true)

                Button(action: { /* AirDrop placeholder */ }) {
                    Image(systemName: "airplayaudio")
                }
                .buttonStyle(.plain)

                Button(action: { /* View options placeholder */ }) {
                    Image(systemName: "line.horizontal.3")
                }
                .buttonStyle(.plain)

                Button(action: { /* Grid/List toggle placeholder */ }) {
                    Image(systemName: "square.grid.2x2")
                }
                .buttonStyle(.plain)

                Button(action: { /* More options placeholder */ }) {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(.plain)

                Button(action: { /* Search placeholder */ }) {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var canGoBack: Bool {
        viewModel.currentDirectory.path != "/" && viewModel.currentDirectory.path != FileManager.default.homeDirectoryForCurrentUser.path
    }
}