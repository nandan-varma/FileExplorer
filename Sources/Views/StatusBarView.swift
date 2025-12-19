import SwiftUI

struct StatusBarView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        HStack {
            // Breadcrumb
            BreadcrumbView(viewModel: viewModel)

            Spacer()

            // Item Count & Storage
            Text("\(viewModel.files.count) items")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("•")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("\(availableStorage()) available")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func availableStorage() -> String {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: viewModel.currentDirectory.path)
            if let freeSize = attributes[.systemFreeSize] as? NSNumber {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useGB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: freeSize.int64Value)
            }
        } catch {}
        return "Unknown"
    }
}