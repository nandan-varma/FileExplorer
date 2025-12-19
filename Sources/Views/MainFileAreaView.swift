import SwiftUI
import AppKit
import QuickLook

struct MainFileAreaView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Column Headers
            HStack(spacing: 0) {
                Text("Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                Text("Size")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)
                Text("Kind")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)
                Text("Date Added")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 140, alignment: .leading)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)

            // File Table (using List for simplicity, as Table might need more setup)
            ScrollViewReader { proxy in
                List(selection: $viewModel.selectedFiles) {
                    ForEach(viewModel.files, id: \.self) { file in
                        FileRowView(file: file, metadata: viewModel.fileMetadata[file] ?? ("0 KB", "Unknown", Date()), isSelected: viewModel.selectedFiles.contains(file), onOpen: { url in
                            viewModel.navigateToDirectory(url)
                        })
                        .id(file)
                    }
                }
                .listStyle(.plain)
                .onChange(of: viewModel.selectedFiles) { oldValue, newValue in
                    if let file = newValue.first {
                        withAnimation {
                            proxy.scrollTo(file, anchor: .center)
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .onKeyPress(.space) {
            if let selectedFile = viewModel.selectedFiles.first {
                viewModel.quickLookURL = selectedFile
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if let currentIndex = viewModel.files.firstIndex(of: viewModel.selectedFiles.first ?? URL(fileURLWithPath: "")) {
                let newIndex = max(0, currentIndex - 1)
                viewModel.selectedFiles = [viewModel.files[newIndex]]
            } else if !viewModel.files.isEmpty {
                viewModel.selectedFiles = [viewModel.files.last!]
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if let currentIndex = viewModel.files.firstIndex(of: viewModel.selectedFiles.first ?? URL(fileURLWithPath: "")) {
                let newIndex = min(viewModel.files.count - 1, currentIndex + 1)
                viewModel.selectedFiles = [viewModel.files[newIndex]]
            } else if !viewModel.files.isEmpty {
                viewModel.selectedFiles = [viewModel.files.first!]
            }
            return .handled
        }
        .onKeyPress(.return) {
            if let file = viewModel.selectedFiles.first, file.hasDirectoryPath {
                viewModel.navigateToDirectory(file)
            }
            return .handled
        }
        .quickLookPreview($viewModel.quickLookURL)
    }
}