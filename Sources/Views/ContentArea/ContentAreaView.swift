import SwiftUI

struct FileItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let size: String?
    let kind: String?
    let dateAdded: String?
    let isFolder: Bool
    let expanded: Bool
}

let sampleFiles: [FileItem] = [
    FileItem(name: "FallQuarterGrades.pdf", size: "81 KB", kind: "PDF Document", dateAdded: "Today at 11:26 AM", isFolder: false, expanded: false),
    FileItem(name: "opencode.jsonc", size: "3 KB", kind: "CodeEdit document", dateAdded: "Yesterday at 3:04 PM", isFolder: false, expanded: false),
    FileItem(name: "Aerial.saver.zip", size: "6.6 MB", kind: "ZIP archive", dateAdded: "Yesterday at 1:07 AM", isFolder: false, expanded: false),
    FileItem(name: "Winter 2026 Fee Information.pdf", size: "85 KB", kind: "PDF Document", dateAdded: "Dec 15, 2025 at 11:30 PM", isFolder: false, expanded: false),
    FileItem(name: "SEATTLE UNIVERSI…STRUCTIONS (1).pdf", size: "50 KB", kind: nil, dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "Dec 15 Boarding Pass SEA to DFW.pdf", size: "550 KB", kind: nil, dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "www.UIndex.org — Op WEBRip-WORLD", size: nil, kind: nil, dateAdded: nil, isFolder: true, expanded: true),
    FileItem(name: "annotated-5110Fi…andanVarma-1.pdf", size: "265 KB", kind: nil, dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "Blip-beta-latest.zip", size: "26.4 MB", kind: nil, dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "answers.pdf", size: "4 KB", kind: nil, dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "CPSC-5610-02-Finals.docx", size: "497 KB", kind: "Word Document", dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "Slide Sets", size: nil, kind: nil, dateAdded: nil, isFolder: true, expanded: false),
    FileItem(name: "CG_slide.zip", size: "46.6 MB", kind: nil, dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "500x500.png", size: "6 KB", kind: "PNG image", dateAdded: nil, isFolder: false, expanded: false),
    FileItem(name: "500x500.svg", size: "5 KB", kind: "SVG document", dateAdded: nil, isFolder: false, expanded: false)
]

struct ContentAreaView: View {
    @ObservedObject var viewModel: ExplorerViewModel
    @State private var hoveredFile: FileItem.ID? = nil
    var body: some View {
        let columns: [GridItem] = [
            GridItem(.fixed(24)), // Icon
            GridItem(.flexible()), // Name
            GridItem(.fixed(80)), // Size
            GridItem(.fixed(120)), // Kind
            GridItem(.fixed(160)) // Date Added
        ]
        VStack(spacing: 0) {
            // Column headers
            LazyVGrid(columns: columns, spacing: 0) {
                Color.clear.frame(width: 24, height: 20) // Icon header placeholder
                SortableHeader(title: "Name", column: .name, viewModel: viewModel, alignment: .leading)
                SortableHeader(title: "Size", column: .size, viewModel: viewModel, alignment: .trailing)
                SortableHeader(title: "Kind", column: .kind, viewModel: viewModel, alignment: .leading)
                SortableHeader(title: "Date Added", column: .dateAdded, viewModel: viewModel, alignment: .leading)
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.gray)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.04))
            Divider()
            // File rows
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(viewModel.files) { file in
                        Group {
                            Image(systemName: file.isFolder ? "folder" : "doc")
                                .foregroundColor(file.isFolder ? .blue : .white)
                                .frame(width: 24)
                            Text(file.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(file.size ?? "")
                                .frame(width: 80, alignment: .trailing)
                            Text(file.kind ?? "")
                                .frame(width: 120, alignment: .leading)
                            Text(file.dateAdded ?? "")
                                .frame(width: 160, alignment: .leading)
                        }
                        .background(
                            (viewModel.selectedFile == file.id) ? Color.blue.opacity(0.2) : (hoveredFile == file.id ? Color.white.opacity(0.08) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectFile(file)
                        }
                        .onHover { hovering in
                            hoveredFile = hovering ? file.id : nil
                        }
                        .simultaneousGesture(TapGesture(count: 2).onEnded {
                            if file.isFolder {
                                // TODO: navigate into folder
                            }
                        })
                    }
                }
            }
        }
    }
}

struct FileRowView: View {
    let file: FileItem
    var selected: Bool = false
    var hovered: Bool = false
    var onSelect: () -> Void = {}
    var onOpen: () -> Void = {}
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: file.isFolder ? "folder" : "doc")
                    .foregroundColor(file.isFolder ? .blue : .white)
                    .frame(width: 24)
                Text(file.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(file.size ?? "").frame(width: 80, alignment: .trailing)
                Text(file.kind ?? "").frame(width: 120, alignment: .leading)
                Text(file.dateAdded ?? "").frame(width: 160, alignment: .leading)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                selected ? Color.accentColor.opacity(0.4) : (hovered ? Color.white.opacity(0.08) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(TapGesture(count: 2).onEnded { onOpen() })
    }
}

#Preview {
    ContentAreaView(viewModel: ExplorerViewModel())
}

struct SortableHeader: View {
    let title: String
    let column: FileSortColumn
    @ObservedObject var viewModel: ExplorerViewModel
    var width: CGFloat? = nil
    var alignment: Alignment = .leading
    var body: some View {
        HStack(spacing: 2) {
            Text(title)
            if viewModel.sortColumn == column {
                Image(systemName: viewModel.sortAscending ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .frame(width: width, alignment: alignment)
        .onTapGesture {
            viewModel.sort(by: column)
        }
        .contentShape(Rectangle())
    }
}
