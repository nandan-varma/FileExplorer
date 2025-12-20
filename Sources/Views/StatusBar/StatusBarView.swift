import SwiftUI

struct StatusBarView: View {
    @ObservedObject var viewModel: ExplorerViewModel
    var body: some View {
        HStack {
            // Breadcrumb
            HStack(spacing: 4) {
                ForEach(Array(viewModel.breadcrumb.enumerated()), id: \.element) { idx, segment in
                    HStack(spacing: 0) {
                        Button(action: { viewModel.navigateToBreadcrumb(index: idx) }) {
                            Text(segment)
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        if idx < viewModel.breadcrumb.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            Spacer()
            // Item count & storage
            VStack(spacing: 2) {
                Text("314 items")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Text("63.38 GB available")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.7))
    }
}

#Preview {
    StatusBarView(viewModel: ExplorerViewModel())
}
