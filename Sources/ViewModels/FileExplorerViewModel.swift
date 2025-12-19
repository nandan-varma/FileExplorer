import Foundation
import AppKit
import UniformTypeIdentifiers

class FileExplorerViewModel: ObservableObject {
    @Published var currentDirectory: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
    @Published var files: [URL] = []
    @Published var selectedFiles: Set<URL> = []
    @Published var quickLookURL: URL?

    @Published var favorites: [URL] = []
    @Published var locations: [URL] = []
    @Published var fileMetadata: [URL: (size: String, kind: String, dateAdded: Date)] = [:]

    init() {
        populateSidebarData()
    }

    private func populateSidebarData() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        favorites = [
            home.appendingPathComponent("Applications"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Pictures")
        ].filter { FileManager.default.fileExists(atPath: $0.path) }

        locations = [
            URL(fileURLWithPath: "/Volumes"), // Placeholder for iCloud
            home,
            URL(fileURLWithPath: "/") // Root
        ]
    }

    func loadFiles() {
        do {
            files = try FileManager.default.explorerContentsOfDirectory(at: currentDirectory)
            // Clear selection if selected files are not in current directory
            selectedFiles = selectedFiles.filter { files.contains($0) }
            loadMetadata()
        } catch {
            print("Error loading files: \(error)")
            files = []
            selectedFiles.removeAll()
        }
    }

    private func loadMetadata() {
        for file in files {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
                let dateAdded = attributes[.creationDate] as? Date ?? Date()
                let kind = UTType(filenameExtension: file.pathExtension)?.localizedDescription ?? "Unknown"
                fileMetadata[file] = (size: formatSize(size), kind: kind, dateAdded: dateAdded)
            } catch {
                fileMetadata[file] = ("0 KB", "Unknown", Date())
            }
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func navigateToDirectory(_ url: URL) {
        currentDirectory = url
        selectedFiles.removeAll()
        loadFiles()
    }

    func goToParentDirectory() {
        let parent = currentDirectory.deletingLastPathComponent()
        guard parent.path != "/" || currentDirectory.path != FileManager.default.homeDirectoryForCurrentUser.path else { return }
        navigateToDirectory(parent)
    }

    func selectFile(_ file: URL) {
        selectedFiles = [file]
    }

    func toggleFileSelection(_ file: URL) {
        if selectedFiles.contains(file) {
            selectedFiles.remove(file)
        } else {
            selectedFiles.insert(file)
        }
    }

    func clearSelection() {
        selectedFiles.removeAll()
    }
}