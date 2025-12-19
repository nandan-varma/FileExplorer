import SwiftUI

struct BreadcrumbView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var fullPathComponents: [String] {
        ["Macintosh HD"] + viewModel.currentDirectory.pathComponents.filter { $0 != "/" }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(fullPathComponents.enumerated()), id: \.offset) { index, component in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }

                    Button(action: {
                        if index == 0 {
                            viewModel.navigateToDirectory(URL(fileURLWithPath: "/"))
                        } else {
                            let pathComponents = fullPathComponents[1...index]
                            let newPath = "/" + pathComponents.joined(separator: "/")
                            viewModel.navigateToDirectory(URL(fileURLWithPath: newPath))
                        }
                    }) {
                        Text(component)
                            .foregroundColor(.primary)
                            .font(.system(size: 12))
                    }
                }
            }
        }
    }
}