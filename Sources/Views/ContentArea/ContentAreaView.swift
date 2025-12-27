import AppKit
import Quartz
import QuickLook
import SwiftUI

/// Handles keyboard shortcuts and mouse interactions for the file explorer
class KeyboardShortcutHandler {
    private var viewModel: ExplorerViewModel

    init(viewModel: ExplorerViewModel) {
        self.viewModel = viewModel
    }

    @MainActor
    func handleSpaceBar() -> URL? {
        guard let selectedFile = viewModel.selectedFile,
            let file = viewModel.filteredFiles.first(where: { $0.id == selectedFile }),
            let url = viewModel.fileURL(for: file)
        else { return nil }

        return url
    }

    @MainActor
    func handleCommandClick(for file: FileItem) {
        if viewModel.selectedFiles.contains(file.id) {
            // Deselect if already selected
            viewModel.deselectFile(file)
        } else {
            // Add to selection
            viewModel.selectAdditionalFile(file)
        }
    }
}

struct ContentAreaView: View {
    @ObservedObject var viewModel: ExplorerViewModel
    @State private var hoveredFile: FileItem.ID? = nil
    @State private var selectionUpdateTrigger: Int = 0

    @State private var keyboardMonitor: Any? = nil
    @State private var globalKeyboardMonitor: Any? = nil
    private let shortcutHandler: KeyboardShortcutHandler

    init(viewModel: ExplorerViewModel) {
        self.viewModel = viewModel
        self.shortcutHandler = KeyboardShortcutHandler(viewModel: viewModel)
    }

    private func selectNextFile() {
        guard !viewModel.filteredFiles.isEmpty else { return }

        let currentIndex: Int
        if let selectedId = viewModel.selectedFiles.first,
            let index = viewModel.filteredFiles.firstIndex(where: { $0.id == selectedId })
        {
            currentIndex = index
        } else if !viewModel.filteredFiles.isEmpty {
            // No selection, start with first file
            currentIndex = 0
        } else {
            return
        }

        let nextIndex = (currentIndex + 1) % viewModel.filteredFiles.count
        let nextFile = viewModel.filteredFiles[nextIndex]
        viewModel.selectFile(nextFile)
        selectionUpdateTrigger += 1
    }

    private func selectPreviousFile() {
        guard !viewModel.filteredFiles.isEmpty else { return }

        let currentIndex: Int
        if let selectedId = viewModel.selectedFiles.first,
            let index = viewModel.filteredFiles.firstIndex(where: { $0.id == selectedId })
        {
            currentIndex = index
        } else if !viewModel.filteredFiles.isEmpty {
            // No selection, start with last file
            currentIndex = viewModel.filteredFiles.count - 1
        } else {
            return
        }

        let prevIndex = currentIndex == 0 ? viewModel.filteredFiles.count - 1 : currentIndex - 1
        let prevFile = viewModel.filteredFiles[prevIndex]
        viewModel.selectFile(prevFile)
        selectionUpdateTrigger += 1
    }

    private func setupKeyboardMonitoring() {
        // Local monitor for when Quick Look is not active
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.viewModel.quickLookURL == nil {
                return self.handleKeyDown(event)
            }
            return event  // Pass through if Quick Look is active
        }

        // Global monitor for when Quick Look is active (higher priority)
        globalKeyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if self.viewModel.quickLookURL != nil {
                _ = self.handleKeyDown(event)
            }
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        // Space bar for Quick Look
        if event.keyCode == 49 {  // Space bar
            if self.viewModel.quickLookURL != nil {
                // Close Quick Look if it's open
                self.viewModel.quickLookURL = nil
                return nil
            } else if let url = self.shortcutHandler.handleSpaceBar() {
                // Open Quick Look
                self.viewModel.quickLookURL = url
                return nil
            }
        }

        // Arrow keys for navigation
        if viewModel.quickLookURL == nil {
            if event.keyCode == 126 {  // Up arrow
                self.selectPreviousFile()
                return nil
            } else if event.keyCode == 125 {  // Down arrow
                self.selectNextFile()
                return nil
            } else if event.keyCode == 123 {  // Left arrow
                self.viewModel.goBack()
                return nil
            } else if event.keyCode == 124 {  // Right arrow
                self.viewModel.goForward()
                return nil
            }
        } else {
            // Quick Look is active: left/right arrow to change previewed file
            guard let currentURL = viewModel.quickLookURL else { return event }
            let files = viewModel.filteredFiles
            guard let currentIndex = files.firstIndex(where: { viewModel.fileURL(for: $0) == currentURL }) else { return event }
            if event.keyCode == 123 { // Left arrow
                let prevIndex = currentIndex == 0 ? files.count - 1 : currentIndex - 1
                let prevFile = files[prevIndex]
                if let url = viewModel.fileURL(for: prevFile) {
                    viewModel.quickLookURL = url
                }
                return nil
            } else if event.keyCode == 124 { // Right arrow
                let nextIndex = (currentIndex + 1) % files.count
                let nextFile = files[nextIndex]
                if let url = viewModel.fileURL(for: nextFile) {
                    viewModel.quickLookURL = url
                }
                return nil
            }
        }

        // Enter key to open (only in normal mode)
        if event.keyCode == 36 && viewModel.quickLookURL == nil {  // Return/Enter
            if let selectedFileId = self.viewModel.selectedFiles.first,
                let file = self.viewModel.filteredFiles.first(where: { $0.id == selectedFileId })
            {
                self.viewModel.openFile(file)
            }
            return nil
        }

        // Delete/Backspace for trash (only in normal mode)
        if (event.keyCode == 51 || event.keyCode == 117) && viewModel.quickLookURL == nil {  // Delete or Forward Delete
            if !self.viewModel.selectedFiles.isEmpty {
                self.viewModel.trash()
            }
            return nil
        }

        // Escape to cancel rename (only in normal mode)
        if event.keyCode == 53 && viewModel.quickLookURL == nil {  // Escape
            if self.viewModel.renamingFileId != nil {
                self.viewModel.cancelRenaming()
                return nil
            }
        }

        return event  // Pass through other events
    }

    var body: some View {
        ZStack {
            Color.clear
            Group {
                if viewModel.viewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
        }
        .onAppear {
            setupKeyboardMonitoring()
        }
        .onDisappear {
            if let monitor = keyboardMonitor {
                NSEvent.removeMonitor(monitor)
                keyboardMonitor = nil
            }
            if let monitor = globalKeyboardMonitor {
                NSEvent.removeMonitor(monitor)
                globalKeyboardMonitor = nil
            }
        }
        .quickLookPreview($viewModel.quickLookURL)
    }

    private var listView: some View {
        let columns: [GridItem] = [
            GridItem(.fixed(24)),  // Icon
            GridItem(.flexible()),  // Name
            GridItem(.fixed(80)),  // Size
            GridItem(.fixed(120)),  // Kind
            GridItem(.fixed(160)),  // Date Added
        ]

        return VStack(spacing: 0) {
            // Column headers
            LazyVGrid(columns: columns, spacing: 0) {
                Color.clear.frame(width: 24, height: 20)  // Icon header placeholder
                SortableHeader(
                    title: "Name", column: .name, viewModel: viewModel, alignment: .leading)
                SortableHeader(
                    title: "Size", column: .size, viewModel: viewModel, alignment: .trailing)
                SortableHeader(
                    title: "Kind", column: .kind, viewModel: viewModel, alignment: .leading)
                SortableHeader(
                    title: "Date Added", column: .dateAdded, viewModel: viewModel,
                    alignment: .leading)
            }
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.gray)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.04))
            Divider()
            // File rows
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(viewModel.filteredFiles) { file in
                        fileRow(for: file)
                    }
                }
            }
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120, maximum: .infinity), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.filteredFiles) { file in
                    VStack(spacing: 6) {
                        VStack(spacing: 4) {
                            if let url = viewModel.fileURL(for: file) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                    .resizable()
                                    .frame(
                                        width: CGFloat(viewModel.iconSize),
                                        height: CGFloat(viewModel.iconSize))
                            } else {
                                Image(systemName: file.isFolder ? "folder" : "doc")
                                    .resizable()
                                    .frame(
                                        width: CGFloat(viewModel.iconSize),
                                        height: CGFloat(viewModel.iconSize)
                                    )
                                    .foregroundColor(file.isFolder ? .blue : .white)
                            }

                            if viewModel.renamingFileId == file.id {
                                TextField(
                                    "Filename", text: $viewModel.renameText,
                                    onCommit: {
                                        viewModel.confirmRename()
                                    }
                                )
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 11))
                                .onExitCommand {
                                    viewModel.cancelRenaming()
                                }
                            } else {
                                Text(file.name)
                                    .font(.system(size: 11))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectFile(file)
                        }
                        .simultaneousGesture(
                            TapGesture(count: 2).onEnded {
                                viewModel.openFile(file)
                            })
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func fileRow(for file: FileItem) -> some View {
        Group {
            if let url = viewModel.fileURL(for: file) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: file.isFolder ? "folder" : "doc")
                    .foregroundColor(file.isFolder ? .blue : .white)
                    .frame(width: 20)
            }

            if viewModel.renamingFileId == file.id {
                TextField(
                    "Filename", text: $viewModel.renameText,
                    onCommit: {
                        viewModel.confirmRename()
                    }
                )
                .textFieldStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onExitCommand {
                    viewModel.cancelRenaming()
                }
            } else {
                Text(file.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(file.size ?? "")
                .frame(width: 80, alignment: .trailing)
            Text(file.kind ?? "")
                .frame(width: 120, alignment: .leading)
            Text(file.dateAdded ?? "")
                .frame(width: 160, alignment: .leading)
        }
        .background(
            (viewModel.selectedFiles.contains(file.id))
                ? Color.blue.opacity(0.2)
                : (hoveredFile == file.id ? Color.white.opacity(0.08) : Color.clear)
        )
        .id(selectionUpdateTrigger) // Force update on selection change
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectFile(file)
        }
        .onHover { hovering in
            hoveredFile = hovering ? file.id : nil
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                viewModel.openFile(file)
            })
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
