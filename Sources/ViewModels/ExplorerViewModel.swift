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
    @Published var currentFolderURL: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var selectedFile: FileItem.ID? = nil
    @Published var selectedFiles: Set<FileItem.ID> = []
    @Published var sortColumn: FileSortColumn = .dateAdded
    @Published var sortAscending: Bool = false
    
    // Search
    @Published var searchText: String = ""

    // Error handling
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false

    // Simple directory cache for performance (LRU with max 10 entries)
    private var directoryCache: [URL: [FileItem]] = [:]
    private var cacheOrder: [URL] = []
    private let maxCacheSize = 10

    // Breadcrumb
    @Published var breadcrumb: [String] = ["Macintosh HD", "Users", NSUserName(), "Downloads"]
    
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

    private func cacheFiles(_ files: [FileItem], for url: URL) {
        directoryCache[url] = files
        cacheOrder.append(url)

        // Maintain LRU cache size
        if cacheOrder.count > maxCacheSize {
            let oldestURL = cacheOrder.removeFirst()
            directoryCache.removeValue(forKey: oldestURL)
        }
    }

    private func getCachedFiles(for url: URL) -> [FileItem]? {
        if let cached = directoryCache[url] {
            // Move to end (most recently used)
            if let index = cacheOrder.firstIndex(of: url) {
                cacheOrder.remove(at: index)
                cacheOrder.append(url)
            }
            return cached
        }
        return nil
    }

    private func errorMessageForError(_ error: NSError) -> String {
        var errorMsg = "Unable to load folder contents."

        if error.domain == NSCocoaErrorDomain {
            switch error.code {
            case NSFileReadNoPermissionError:
                errorMsg = "Permission denied. Please grant full disk access in System Settings > Privacy & Security."
            case NSFileReadNoSuchFileError:
                errorMsg = "The folder no longer exists."
            case NSFileReadInvalidFileNameError:
                errorMsg = "Invalid folder path."
            case NSFileReadCorruptFileError:
                errorMsg = "The folder appears to be corrupted."
            case NSFileReadInapplicableStringEncodingError:
                errorMsg = "Unable to read folder metadata due to encoding issues."
            case NSFileReadUnsupportedSchemeError:
                errorMsg = "Unsupported file system format."
            case NSFileReadTooLargeError:
                errorMsg = "The folder is too large to display."
            case NSFileReadUnknownError:
                errorMsg = "An unknown file system error occurred."
            default:
                if error.code >= 0 && error.code <= 999 {
                    errorMsg = "File system error (\(error.code)): \(error.localizedDescription)"
                } else {
                    errorMsg = "Unexpected error: \(error.localizedDescription)"
                }
            }
        } else if error.domain == NSPOSIXErrorDomain {
            // Handle POSIX errors
            switch error.code {
            case Int(ENOENT):
                errorMsg = "The folder no longer exists."
            case Int(EACCES):
                errorMsg = "Permission denied to access this folder."
            case Int(ENOTDIR):
                errorMsg = "The selected item is not a folder."
            case Int(EIO):
                errorMsg = "Input/output error while reading the folder."
            case Int(ENOSPC):
                errorMsg = "No space left on device."
            case Int(EROFS):
                errorMsg = "The file system is read-only."
            default:
                errorMsg = "System error: \(error.localizedDescription)"
            }
        } else {
            errorMsg = "Error: \(error.localizedDescription)"
        }

        return errorMsg
    }

    private func isValidFileURL(_ url: URL) -> Bool {
        // Comprehensive path validation for security
        guard url.scheme == "file" else { return false }
        guard url.host == nil || url.host == "" else { return false } // No remote hosts

        do {
            // Normalize the URL by resolving symlinks and getting absolute path
            let resolvedURL = try url.resolvingSymlinksInPath()
            let normalizedPath = resolvedURL.path

            // Check for path traversal attempts (multiple patterns)
            let traversalPatterns = ["../", "..\\", "%2e%2e%2f", "%2e%2e/", "%2e%2e\\"]
            for pattern in traversalPatterns {
                if normalizedPath.contains(pattern) { return false }
            }

            // Prevent access to system-critical directories
            let forbiddenPaths = ["/System", "/usr", "/bin", "/sbin", "/private", "/cores"]
            for forbidden in forbiddenPaths {
                if normalizedPath.hasPrefix(forbidden) { return false }
            }

            // Check if the resolved path exists and is accessible
            let fm = FileManager.default
            var isDirectory: ObjCBool = false
            let exists = fm.fileExists(atPath: normalizedPath, isDirectory: &isDirectory)

            // Additional security: verify we can actually read the directory
            if exists && isDirectory.boolValue {
                do {
                    let _ = try fm.contentsOfDirectory(atPath: normalizedPath)
                    return true
                } catch {
                    return false // Can't read directory despite it existing
                }
            }

            return false
        } catch {
            return false // Failed to resolve symlinks or other validation error
        }
    }

    func loadFiles(at url: URL) {
        // Check cache first for instant loading
        if let cachedFiles = getCachedFiles(for: url) {
            self.files = cachedFiles
            return
        }

        // Perform file operations on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            do {
                let contents = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles])

                let fileItems = contents.map { fileURL in
                    let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isFolder = resourceValues?.isDirectory ?? false
                    let size = isFolder ? nil : (resourceValues?.fileSize).flatMap { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) }
                    let kind = isFolder ? "Folder" : fileURL.pathExtension.uppercased()
                    let dateAdded = resourceValues?.contentModificationDate.map { Self.dateFormatter.string(from: $0) }
                    return FileItem(
                        name: fileURL.lastPathComponent,
                        size: size,
                        kind: kind,
                        dateAdded: dateAdded,
                        isFolder: isFolder,
                        expanded: false
                    )
                }.sorted { $0.name.lowercased() < $1.name.lowercased() }

                // Cache the results
                self.cacheFiles(fileItems, for: url)

                // Update UI on main thread
                DispatchQueue.main.async {
                    self.files = fileItems
                }
            } catch let error as NSError {
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.files = []
                    self.showError(self.errorMessageForError(error))
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
        // Simple breadcrumb update - in a real implementation, you'd want more sophisticated path handling
        let pathComponents = url.pathComponents
        // Find the index where the path diverges from the root
        // For now, just set a basic breadcrumb
        breadcrumb = ["Macintosh HD"] + pathComponents.dropFirst()
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
    
    // MARK: - Sorting
    func sort(by column: FileSortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
        // TODO: Sort files
    }
    
    // MARK: - Search
    func updateSearch(_ text: String) {
        searchText = text
        // TODO: Filter files
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
        case .nandan: return NSUserName()
        case .dev: return "dev"
        case .icloud: return "iCloud Drive"
        case .home: return NSUserName()
        case .macbook: return "Nandan’s MacBook Air"
        }
    }
}

enum FileSortColumn {
    case name, size, kind, dateAdded
}
