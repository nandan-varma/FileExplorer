import SwiftUI
import AppKit

struct FileRowView: View {
    let file: URL
    let metadata: (size: String, kind: String, dateAdded: Date)
    let isSelected: Bool
    let onOpen: (URL) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Name
            HStack(spacing: 12) {
                Image(nsImage: getIcon(for: file))
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(file.lastPathComponent)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)

            // Size
            Text(metadata.size)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)

            // Kind
            Text(metadata.kind)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            // Date Added
            Text(formatDate(metadata.dateAdded))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 140, alignment: .leading)
                .padding(.trailing, 16)
        }
        .padding(.vertical, 4)
        .listRowBackground(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            // Selection handled by List
        }
        .onTapGesture(count: 2) {
            if file.hasDirectoryPath {
                onOpen(file)
            }
        }
    }

    private func getIcon(for url: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}