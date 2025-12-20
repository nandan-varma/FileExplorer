import Foundation
import AppKit

class NavigationService: ObservableObject {
    @Published var navigationHistory: [URL] = []
    @Published var currentHistoryIndex: Int = -1
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentFolderURL: URL = FileManager.default.homeDirectoryForCurrentUser
    @Published var breadcrumb: [String] = ["Macintosh HD", "Users", "nandan", "Downloads"]

    private let fileManager = FileManager.default

    init() {
        // Start with Downloads folder as initial location
        let downloadsURL = urlForSidebarItem(.downloads)
        currentFolderURL = downloadsURL
        navigationHistory = [downloadsURL]
        currentHistoryIndex = 0
        updateNavigationState()
        updateBreadcrumb(for: downloadsURL)
    }

    // MARK: - Navigation
    func navigateToURL(_ url: URL) -> Bool {
        guard isValidFileURL(url) else { return false }

        // If we're not at the end of history, truncate forward history
        if currentHistoryIndex < navigationHistory.count - 1 {
            navigationHistory = Array(navigationHistory.prefix(currentHistoryIndex + 1))
        }

        // Add new URL to history
        navigationHistory.append(url)
        currentHistoryIndex = navigationHistory.count - 1
        currentFolderURL = url
        updateNavigationState()
        updateBreadcrumb(for: url)
        return true
    }

    func goBack() -> URL? {
        guard canGoBack else { return nil }
        currentHistoryIndex -= 1
        let url = navigationHistory[currentHistoryIndex]
        currentFolderURL = url
        updateNavigationState()
        updateBreadcrumb(for: url)
        return url
    }

    func goForward() -> URL? {
        guard canGoForward else { return nil }
        currentHistoryIndex += 1
        let url = navigationHistory[currentHistoryIndex]
        currentFolderURL = url
        updateNavigationState()
        updateBreadcrumb(for: url)
        return url
    }

    func navigateToBreadcrumb(index: Int) {
        breadcrumb = Array(breadcrumb.prefix(index + 1))
        // This would typically trigger a navigation to the corresponding URL
        // For now, we'll just update the breadcrumb display
    }

    // MARK: - Sidebar Navigation
    func selectSidebarItem(_ item: SidebarItemType) -> URL {
        let url = urlForSidebarItem(item)
        _ = navigateToURL(url) // Navigate and return success status
        return url
    }

    // MARK: - Private Helpers
    private func updateNavigationState() {
        canGoBack = currentHistoryIndex > 0
        canGoForward = currentHistoryIndex < navigationHistory.count - 1
    }

    private func updateBreadcrumb(for url: URL) {
        let pathComponents = url.pathComponents
        if pathComponents.first == "/" {
            breadcrumb = ["Macintosh HD"] + pathComponents.dropFirst().map { $0 }
        } else {
            breadcrumb = pathComponents
        }
    }

    private func isValidFileURL(_ url: URL) -> Bool {
        guard url.scheme == "file" else { return false }

        let path = url.path
        guard !path.contains("../") && !path.contains("..\\") else { return false }

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private func urlForSidebarItem(_ item: SidebarItemType) -> URL {
        switch item {
        case .downloads:
            return fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        case .documents:
            return fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        case .desktop:
            return fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        case .pictures:
            return fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
        case .applications:
            return URL(fileURLWithPath: "/Applications")
        case .icloud:
            return fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents")
        case .home, .nandan:
            return fileManager.homeDirectoryForCurrentUser
        case .dev:
            return fileManager.homeDirectoryForCurrentUser.appendingPathComponent("dev")
        case .macbook:
            return URL(fileURLWithPath: "/")
        case .recents, .shared:
            return fileManager.homeDirectoryForCurrentUser // fallback
        }
    }
}