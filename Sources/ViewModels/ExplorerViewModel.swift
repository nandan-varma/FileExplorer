import Foundation
import SwiftUI
import AppKit

class ExplorerViewModel: ObservableObject {
    // MARK: - File list state (inlined from SearchService)
    private var _files: [FileItem] = []
    private var _filteredFiles: [FileItem] = []

    // MARK: - Navigation state (inlined from NavigationService)
    private var _navigationHistory: [URL] = []
    private var _currentHistoryIndex: Int = -1
    private var _currentFolderURL: URL = FileManager.default.homeDirectoryForCurrentUser
    private var _breadcrumb: [String] = ["Macintosh HD", "Users", "nandan", "Downloads"]

    // MARK: - Selection state (inlined from SelectionService)
    private var _selectedFile: FileItem.ID? = nil
    private var _selectedFiles: Set<FileItem.ID> = []

    // MARK: - Sorting state (inlined from SortingService)
    private var _sortColumn: FileSortColumn = .dateAdded
    private var _sortAscending: Bool = false

    // MARK: - Search state (inlined from SearchService)
    private var _searchText: String = ""
    private var _searchDebounceTimer: Timer?

    // MARK: - View state (inlined from ViewStateService)
    private var _viewMode: ViewMode = .list
    private var _showHiddenFiles: Bool = false
    private var _iconSize: Double = 64

    // MARK: - Error state (inlined from ErrorHandlingService)
    private var _errorMessage: String? = nil
    private var _showErrorAlert: Bool = false

    // MARK: - Published Properties
    @Published var quickLookURL: URL? = nil
    @Published var renamingFileId: FileItem.ID? = nil
    @Published var renameText: String = ""
    @Published var selectedSidebarItem: SidebarItemType = .downloads

    // MARK: - Computed Properties
    var files: [FileItem] {
        get { _files }
        set {
            _files = newValue
            updateFilteredFiles()
        }
    }

    var filteredFiles: [FileItem] {
        _filteredFiles
    }

    var currentFolderURL: URL {
        _currentFolderURL
    }

    var canGoBack: Bool {
        _currentHistoryIndex > 0
    }

    var canGoForward: Bool {
        _currentHistoryIndex < _navigationHistory.count - 1
    }

    var breadcrumb: [String] {
        _breadcrumb
    }

    var viewMode: ViewMode {
        get { _viewMode }
        set { _viewMode = newValue }
    }

    var iconSize: Double {
        get { _iconSize }
        set { _iconSize = newValue }
    }

    var showHiddenFiles: Bool {
        get { _showHiddenFiles }
        set { _showHiddenFiles = newValue }
    }

    var sortColumn: FileSortColumn {
        get { _sortColumn }
        set { _sortColumn = newValue }
    }

    var sortAscending: Bool {
        get { _sortAscending }
        set { _sortAscending = newValue }
    }

    var searchText: String {
        get { _searchText }
        set {
            _searchText = newValue
            updateSearch(newValue)
        }
    }

    var selectedFile: FileItem.ID? {
        _selectedFile
    }

    var selectedFiles: Set<FileItem.ID> {
        _selectedFiles
    }

    var errorMessage: String? {
        get { _errorMessage }
        set { _errorMessage = newValue }
    }

    var showErrorAlert: Bool {
        get { _showErrorAlert }
        set { _showErrorAlert = newValue }
    }

    // MARK: - Initialization
    init() {
        // Start with Downloads folder as initial location
        let downloadsURL = urlForSidebarItem(.downloads)
        _currentFolderURL = downloadsURL
        selectedSidebarItem = .downloads

        // Initialize navigation history with the downloads folder
        _navigationHistory = [downloadsURL]
        _currentHistoryIndex = 0
        updateBreadcrumb(for: downloadsURL)
        loadFiles(at: downloadsURL)
    }

    // MARK: - File Operations
    func fileURL(for file: FileItem) -> URL? {
        let filePath = currentFolderURL.appendingPathComponent(file.name)
        let fm = FileManager.default
        return fm.fileExists(atPath: filePath.path) ? filePath : nil
    }

    func loadFiles(at url: URL) {
        // Perform file operations on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            do {
                let options: FileManager.DirectoryEnumerationOptions = self._showHiddenFiles ? [] : [.skipsHiddenFiles]
                let contents = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: options)

                let fileItems = contents.map { fileURL in
                    let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isFolder = resourceValues?.isDirectory ?? false
                    let sizeBytes = resourceValues?.fileSize.map { Int64($0) }
                    let size = isFolder ? nil : sizeBytes.flatMap { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
                    let kind = isFolder ? "Folder" : fileURL.pathExtension.uppercased()
                    let dateModified = resourceValues?.contentModificationDate
                    let dateAdded = dateModified.map { Self.dateFormatter.string(from: $0) }
                    return FileItem(
                        name: fileURL.lastPathComponent,
                        size: size,
                        sizeBytes: sizeBytes,
                        kind: kind,
                        dateAdded: dateAdded,
                        dateModified: dateModified,
                        isFolder: isFolder,
                        expanded: false
                    )
                }

                // Update UI on main thread
                DispatchQueue.main.async {
                    self.files = fileItems
                }
            } catch let error as NSError {
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.files = []
                    var errorMsg = "Unable to load folder contents."
                    if error.domain == NSCocoaErrorDomain {
                        switch error.code {
                        case NSFileReadNoPermissionError:
                            errorMsg = "Permission denied. Please grant full disk access in System Settings > Privacy & Security."
                        case NSFileReadNoSuchFileError:
                            errorMsg = "The folder no longer exists."
                        case NSFileReadInvalidFileNameError:
                            errorMsg = "Invalid folder path."
                        default:
                            errorMsg = "File system error: \(error.localizedDescription)"
                        }
                    }
                    self.showError(errorMsg)
                }
            }
        }
    }

    // MARK: - Navigation
    func navigateToURL(_ url: URL) {
        guard isValidFileURL(url) else {
            showError("Invalid or inaccessible path.")
            return
        }

        // If we're not at the end of history, truncate forward history
        if _currentHistoryIndex < _navigationHistory.count - 1 {
            _navigationHistory = Array(_navigationHistory.prefix(_currentHistoryIndex + 1))
        }

        // Add new URL to history
        _navigationHistory.append(url)
        _currentHistoryIndex = _navigationHistory.count - 1

        // Update current folder and load files
        _currentFolderURL = url
        loadFiles(at: url)
        updateNavigationState()
        updateBreadcrumb(for: url)
    }

    func goBack() {
        guard canGoBack else { return }
        _currentHistoryIndex -= 1
        let url = _navigationHistory[_currentHistoryIndex]
        _currentFolderURL = url
        loadFiles(at: url)
        updateNavigationState()
        updateBreadcrumb(for: url)
    }

    func goForward() {
        guard canGoForward else { return }
        _currentHistoryIndex += 1
        let url = _navigationHistory[_currentHistoryIndex]
        _currentFolderURL = url
        loadFiles(at: url)
        updateNavigationState()
        updateBreadcrumb(for: url)
    }

    func navigateToBreadcrumb(index: Int) {
        _breadcrumb = Array(_breadcrumb.prefix(index + 1))
        // This would typically trigger a navigation to the corresponding URL
        // For now, we'll just update the breadcrumb display
    }

    // MARK: - Sidebar
    func selectSidebarItem(_ item: SidebarItemType) {
        selectedSidebarItem = item
        // Update files for selected item
        let url = urlForSidebarItem(item)
        navigateToURL(url)
    }

    // MARK: - File Selection
    func selectFile(_ file: FileItem) {
        _selectedFile = file.id
        _selectedFiles = [file.id]
    }

    func selectAdditionalFile(_ file: FileItem) {
        _selectedFiles.insert(file.id)
        if _selectedFile == nil {
            _selectedFile = file.id
        }
    }

    func deselectFile(_ file: FileItem) {
        _selectedFiles.remove(file.id)
        if _selectedFile == file.id {
            _selectedFile = _selectedFiles.first
        }
    }

    func clearSelection() {
        _selectedFile = nil
        _selectedFiles.removeAll()
    }

    func selectNextFile() {
        guard !filteredFiles.isEmpty else { return }

        let currentIndex: Int
        if let selectedId = _selectedFile,
           let index = filteredFiles.firstIndex(where: { $0.id == selectedId }) {
            currentIndex = index
        } else if !filteredFiles.isEmpty {
            currentIndex = 0
        } else {
            return
        }

        let nextIndex = (currentIndex + 1) % filteredFiles.count
        let nextFile = filteredFiles[nextIndex]
        selectFile(nextFile)
    }

    func selectPreviousFile() {
        guard !filteredFiles.isEmpty else { return }

        let currentIndex: Int
        if let selectedId = _selectedFile,
           let index = filteredFiles.firstIndex(where: { $0.id == selectedId }) {
            currentIndex = index
        } else if !filteredFiles.isEmpty {
            currentIndex = filteredFiles.count - 1
        } else {
            return
        }

        let prevIndex = currentIndex == 0 ? filteredFiles.count - 1 : currentIndex - 1
        let prevFile = filteredFiles[prevIndex]
        selectFile(prevFile)
    }

    // MARK: - File Operations
    func openFile(_ file: FileItem) {
        guard let url = fileURL(for: file) else {
            showError("Unable to access file.")
            return
        }

        if file.isFolder {
            navigateToURL(url)
        } else {
            let fm = FileManager.default
            guard fm.fileExists(atPath: url.path) else {
                showError("File no longer exists.")
                return
            }
            NSWorkspace.shared.open(url)
        }
    }

    func copySelectedFiles() {
        let urls = selectedFileURLs()
        copyFilesToPasteboard(urls)
    }

    func duplicateSelectedFiles() {
        let urls = selectedFileURLs()
        for url in urls {
            let fileManager = FileManager.default
            let duplicateName = generateDuplicateName(for: url)
            let duplicateURL = url.deletingLastPathComponent().appendingPathComponent(duplicateName)

            do {
                try fileManager.copyItem(at: url, to: duplicateURL)
                loadFiles(at: currentFolderURL) // Refresh the view
            } catch {
                showError("Failed to duplicate file: \(error.localizedDescription)")
            }
        }
    }

    func trash() {
        let urls = selectedFileURLs()
        for url in urls {
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            } catch {
                showError("Failed to move to trash: \(error.localizedDescription)")
            }
        }
        loadFiles(at: currentFolderURL) // Refresh the view
        clearSelection()
    }

    func compressSelectedFiles() {
        let urls = selectedFileURLs()
        guard !urls.isEmpty else { return }

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let archiveName = "Archive.zip"
        let archiveURL = tempDir.appendingPathComponent(archiveName)

        // Remove existing archive if it exists
        try? fileManager.removeItem(at: archiveURL)

        do {
            // Create zip archive using Process (since FileManager.zipItems might not be available)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.arguments = ["-r", archiveURL.path] + urls.map { $0.path }

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Move archive to current directory
                let destinationURL = currentFolderURL.appendingPathComponent(archiveName)
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: archiveURL, to: destinationURL)
                loadFiles(at: currentFolderURL) // Refresh the view
            } else {
                showError("Failed to create zip archive")
            }
        } catch {
            showError("Failed to compress files: \(error.localizedDescription)")
        }
    }

    func showGetInfo() {
        let urls = selectedFileURLs()
        if let firstURL = urls.first {
            NSWorkspace.shared.selectFile(firstURL.path, inFileViewerRootedAtPath: firstURL.deletingLastPathComponent().path)
        }
    }

    func createNewFolder() {
        let fileManager = FileManager.default
        let baseName = "Untitled Folder"
        var folderName = baseName
        var counter = 1

        while fileManager.fileExists(atPath: currentFolderURL.appendingPathComponent(folderName).path) {
            folderName = "\(baseName) \(counter)"
            counter += 1
        }

        let folderURL = currentFolderURL.appendingPathComponent(folderName)

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            loadFiles(at: currentFolderURL) // Refresh the view

            // Find the new folder and start renaming it
            if let newFolder = filteredFiles.first(where: { $0.name == folderName }) {
                startRenaming(newFolder)
            }
        } catch {
            showError("Failed to create folder: \(error.localizedDescription)")
        }
    }

    func createNewFile() {
        let fileManager = FileManager.default
        let baseName = "Untitled.txt"
        var fileName = baseName
        var counter = 1

        while fileManager.fileExists(atPath: currentFolderURL.appendingPathComponent(fileName).path) {
            let nameWithoutExtension = "Untitled \(counter)"
            fileName = "\(nameWithoutExtension).txt"
            counter += 1
        }

        let fileURL = currentFolderURL.appendingPathComponent(fileName)

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            loadFiles(at: currentFolderURL) // Refresh the view

            // Find the new file and start renaming it
            if let newFile = filteredFiles.first(where: { $0.name == fileName }) {
                startRenaming(newFile)
            }
        } catch {
            showError("Failed to create file: \(error.localizedDescription)")
        }
    }

    // MARK: - Renaming
    func startRenaming(_ file: FileItem) {
        guard fileURL(for: file) != nil else { return }
        renamingFileId = file.id
        renameText = file.name
    }

    func cancelRenaming() {
        renamingFileId = nil
        renameText = ""
    }

    func confirmRename() {
        guard let fileId = renamingFileId,
              let file = filteredFiles.first(where: { $0.id == fileId }),
              let oldURL = fileURL(for: file),
              !renameText.isEmpty && renameText != file.name else {
            cancelRenaming()
            return
        }

        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(renameText)

        do {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
            loadFiles(at: currentFolderURL) // Refresh the view
            cancelRenaming()
        } catch {
            showError("Failed to rename file: \(error.localizedDescription)")
        }
    }

    // MARK: - Search & Sorting
    func updateSearch(_ text: String) {
        _searchText = text
        updateFilteredFiles()
    }

    func sort(by column: FileSortColumn) {
        if _sortColumn == column {
            _sortAscending.toggle()
        } else {
            _sortColumn = column
            _sortAscending = true
        }
        applySorting()
        // Force UI update since filteredFiles is computed
        objectWillChange.send()
    }

    // MARK: - View State
    func toggleViewMode() {
        _viewMode = _viewMode == .list ? .grid : .list
    }

    func toggleHiddenFiles(_ show: Bool) {
        _showHiddenFiles = show
        // Reload current directory to apply filter
        loadFiles(at: currentFolderURL)
    }

    func setIconSize(_ size: Double) {
        _iconSize = size
    }

    // MARK: - Toolbar Actions (stubs)
    func quickLook() { /* TODO: Implement Quick Look */ }
    func newTab() { /* TODO: Implement New Tab */ }
    func openVSCode() { /* TODO: Implement VS Code integration */ }

    // MARK: - Private Methods
    private func urlForSidebarItem(_ item: SidebarItemType) -> URL {
        let fm = FileManager.default
        switch item {
        case .downloads:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        case .documents:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        case .desktop:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        case .pictures:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
        case .applications:
            return URL(fileURLWithPath: "/Applications")
        case .icloud:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents")
        case .home, .nandan:
            return fm.homeDirectoryForCurrentUser
        case .dev:
            return fm.homeDirectoryForCurrentUser.appendingPathComponent("dev")
        case .macbook:
            return URL(fileURLWithPath: "/")
        case .recents, .shared:
            return fm.homeDirectoryForCurrentUser // fallback
        }
    }

    private func updateBreadcrumb(for url: URL) {
        let pathComponents = url.pathComponents
        if pathComponents.first == "/" {
            _breadcrumb = ["Macintosh HD"] + pathComponents.dropFirst().map { $0 }
        } else {
            _breadcrumb = pathComponents
        }
    }

    private func updateFilteredFiles() {
        if _searchText.isEmpty {
            _filteredFiles = _files
        } else {
            _filteredFiles = _files.filter { file in
                file.name.lowercased().contains(_searchText.lowercased())
            }
        }
        applySorting()
    }



    private func performSearch(_ text: String) {
        _searchText = text
        updateFilteredFiles()
    }

    func applySorting() {
        _filteredFiles.sort { lhs, rhs in
            let result: Bool
            switch _sortColumn {
            case .name:
                result = lhs.name.lowercased() < rhs.name.lowercased()
            case .size:
                if lhs.isFolder && rhs.isFolder {
                    result = lhs.name.lowercased() < rhs.name.lowercased()
                } else if lhs.isFolder {
                    result = true // folders first
                } else if rhs.isFolder {
                    result = false
                } else {
                    result = (lhs.sizeBytes ?? 0) < (rhs.sizeBytes ?? 0)
                }
            case .kind:
                result = (lhs.kind ?? "").lowercased() < (rhs.kind ?? "").lowercased()
            case .dateAdded:
                result = (lhs.dateModified ?? Date.distantPast) < (rhs.dateModified ?? Date.distantPast)
            }
            return _sortAscending ? result : !result
        }
    }

    private func showError(_ message: String) {
        _errorMessage = message
        _showErrorAlert = true
    }

    private func isValidFileURL(_ url: URL) -> Bool {
        guard url.scheme == "file" else { return false }

        let path = url.path
        guard !path.contains("../") && !path.contains("..\\") else { return false }

        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private func updateNavigationState() {
        // Update computed properties by triggering objectWillChange
        objectWillChange.send()
    }

    private func selectedFileURLs() -> [URL] {
        return _selectedFiles.compactMap { selectedFileId in
            filteredFiles.first(where: { $0.id == selectedFileId }).flatMap { fileURL(for: $0) }
        }
    }

    private func generateDuplicateName(for url: URL) -> String {
        let fileName = url.lastPathComponent
        let baseName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        let fileManager = FileManager.default
        var duplicateName = fileName
        var counter = 1

        while fileManager.fileExists(atPath: url.deletingLastPathComponent().appendingPathComponent(duplicateName).path) {
            if fileExtension.isEmpty {
                duplicateName = "\(baseName) \(counter)"
            } else {
                duplicateName = "\(baseName) \(counter).\(fileExtension)"
            }
            counter += 1
        }

        return duplicateName
    }

    private func copyFilesToPasteboard(_ urls: [URL]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(urls as [NSPasteboardWriting])
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}