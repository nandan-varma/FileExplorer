import Foundation
import SwiftUI

class ExplorerViewModel: ObservableObject {
    // Returns the file URL for a given FileItem, if it exists in the current folder
    func fileURL(for file: FileItem) -> URL? {
        let fm = FileManager.default
        let folderURL = currentFolderURL
        let filePath = folderURL.appendingPathComponent(file.name)
        return fm.fileExists(atPath: filePath.path) ? filePath : nil
    }

        // Toolbar actions (stubs)
        func quickLook() { /* TODO: Implement Quick Look */ }
        func newTab() { /* TODO: Implement New Tab */ }
        func openVSCode() { /* TODO: Implement VS Code integration */ }
        func trash() { /* TODO: Implement Trash */ }
        func share() { /* TODO: Implement Share */ }
        func viewOptions() { /* TODO: Implement View Options */ }
        func toggleViewMode() { /* TODO: Implement Grid/List toggle */ }
        func moreOptions() { /* TODO: Implement More Options */ }
    // Sidebar
    @Published var selectedSidebarItem: SidebarItemType = .downloads
    @Published var sidebarItems: [SidebarItemType] = SidebarItemType.allCases
    
    // Navigation History (URL-based)
    @Published var navigationHistory: [URL] = []
    @Published var currentHistoryIndex: Int = -1
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    
    // File list
    @Published var files: [FileItem] = []
    @Published var filteredFiles: [FileItem] = []
    @Published var currentFolderURL: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var selectedFile: FileItem.ID? = nil
    @Published var selectedFiles: Set<FileItem.ID> = []
    @Published var sortColumn: FileSortColumn = .dateAdded
    @Published var sortAscending: Bool = false

    // Search
    @Published var searchText: String = ""
    private var searchDebounceTimer: Timer?

    // Quick Look
    @Published var quickLookURL: URL? = nil

    // View options
    @Published var viewMode: ViewMode = .list

    // Error handling
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false

    // Breadcrumb
    @Published var breadcrumb: [String] = ["Macintosh HD", "Users", "nandan", "Downloads"]
    
    // MARK: - Sidebar
    func selectSidebarItem(_ item: SidebarItemType) {
        selectedSidebarItem = item
        // Update files for selected item
        let url = urlForSidebarItem(item)
        navigateToURL(url)
    }

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

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    private func isValidFileURL(_ url: URL) -> Bool {
        // Basic validation: must be file URL, not contain .. for path traversal
        guard url.scheme == "file" else { return false }

        let path = url.path
        // Check for path traversal attempts
        guard !path.contains("../") && !path.contains("..\\") else { return false }

        // Check if the path exists and is a directory
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func loadFiles(at url: URL) {
        // Perform file operations on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            do {
                let contents = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles])

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
                    self.updateFilteredFiles()
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

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    // Load files for initial folder on init
    init() {
        // Start with Downloads folder as initial location
        let downloadsURL = urlForSidebarItem(.downloads)
        currentFolderURL = downloadsURL
        selectedSidebarItem = .downloads

        // Initialize navigation history with the downloads folder
        navigationHistory = [downloadsURL]
        currentHistoryIndex = 0
        updateNavigationState()
        loadFiles(at: downloadsURL)
    }
    
    // MARK: - Navigation
    func navigateToURL(_ url: URL) {
        // Validate URL before navigation
        guard isValidFileURL(url) else {
            showError("Invalid or inaccessible path.")
            return
        }

        // If we're not at the end of history, truncate forward history
        if currentHistoryIndex < navigationHistory.count - 1 {
            navigationHistory = Array(navigationHistory.prefix(currentHistoryIndex + 1))
        }

        // Add new URL to history
        navigationHistory.append(url)
        currentHistoryIndex = navigationHistory.count - 1

        // Update current folder and load files
        currentFolderURL = url
        loadFiles(at: url)
        updateNavigationState()
        updateBreadcrumb(for: url)
    }

    func goBack() {
        guard canGoBack else { return }
        currentHistoryIndex -= 1
        let url = navigationHistory[currentHistoryIndex]
        currentFolderURL = url
        loadFiles(at: url)
        updateNavigationState()
        updateBreadcrumb(for: url)
    }

    func goForward() {
        guard canGoForward else { return }
        currentHistoryIndex += 1
        let url = navigationHistory[currentHistoryIndex]
        currentFolderURL = url
        loadFiles(at: url)
        updateNavigationState()
        updateBreadcrumb(for: url)
    }

    private func updateNavigationState() {
        canGoBack = currentHistoryIndex > 0
        canGoForward = currentHistoryIndex < navigationHistory.count - 1
    }
    
    // MARK: - File Selection
    func selectFile(_ file: FileItem) {
        selectedFile = file.id
        selectedFiles = [file.id]
    }

    func openFile(_ file: FileItem) {
        guard let url = fileURL(for: file) else {
            showError("Unable to access file.")
            return
        }

        if file.isFolder {
            // Navigate into the folder
            navigateToURL(url)
        } else {
            // Validate file exists before opening
            let fm = FileManager.default
            guard fm.fileExists(atPath: url.path) else {
                showError("File no longer exists.")
                return
            }
            // Open file with default application
            NSWorkspace.shared.open(url)
        }
    }

    private func updateBreadcrumb(for url: URL) {
        let pathComponents = url.pathComponents
        if pathComponents.first == "/" {
            breadcrumb = ["Macintosh HD"] + pathComponents.dropFirst().map { $0 }
        } else {
            breadcrumb = pathComponents
        }
    }

    private func updateFilteredFiles() {
        if searchText.isEmpty {
            filteredFiles = files
        } else {
            filteredFiles = files.filter { file in
                file.name.lowercased().contains(searchText.lowercased())
            }
        }
        applySorting()
    }

    private func performSearch(_ text: String) {
        searchText = text
        updateFilteredFiles()
    }

    // MARK: - Sorting
    func sort(by column: FileSortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
        applySorting()
    }

    private func applySorting() {
        filteredFiles.sort { lhs, rhs in
            let result: Bool
            switch sortColumn {
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
            return sortAscending ? result : !result
        }
    }

    // MARK: - Search
    func updateSearch(_ text: String) {
        searchDebounceTimer?.invalidate()
        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.performSearch(text)
        }
    }

    func selectAdditionalFile(_ file: FileItem) {
        selectedFiles.insert(file.id)
        if selectedFile == nil {
            selectedFile = file.id
        }
    }

    func deselectFile(_ file: FileItem) {
        selectedFiles.remove(file.id)
        if selectedFile == file.id {
            selectedFile = selectedFiles.first
        }
    }

    func clearSelection() {
        selectedFile = nil
        selectedFiles.removeAll()
    }
    

    
    // MARK: - Breadcrumb
    func navigateToBreadcrumb(index: Int) {
        breadcrumb = Array(breadcrumb.prefix(index + 1))
        // TODO: Update files for breadcrumb
    }
}

// Sidebar item types
enum SidebarItemType: String, CaseIterable, Identifiable {
    case applications, documents, desktop, downloads, pictures, recents, shared, nandan, dev, icloud, home, macbook
    var id: String { rawValue }
    var label: String {
        switch self {
        case .applications: return "Applications"
        case .documents: return "Documents"
        case .desktop: return "Desktop"
        case .downloads: return "Downloads"
        case .pictures: return "Pictures"
        case .recents: return "Recents"
        case .shared: return "Shared"
        case .nandan: return "nandan"
        case .dev: return "dev"
        case .icloud: return "iCloud Drive"
        case .home: return "nandan"
        case .macbook: return "Nandan’s MacBook Air"
        }
    }
}

enum FileSortColumn {
    case name, size, kind, dateAdded
}

enum ViewMode {
    case list, grid
}
