import Foundation
import AppKit

enum ViewMode { case list, icon, column }

class FileExplorerViewModel: ObservableObject {
    @Published var currentDirectory: FileItem?
    @Published var items: [FileItem] = []
    @Published var searchQuery = ""
    @Published var viewMode: ViewMode = .list
    @Published var selectedItemIDs: Set<FileItem.ID> = []

    private let fileService: FileService
    private var navigationStack: [FileItem] = []
    private var currentIndex = -1

    init(fileService: FileService = FileManagerService()) {
        self.fileService = fileService
        if let home = FileManager.default.urls(for: .userDirectory, in: .userDomainMask).first {
            navigateToDirectory(FileItem(url: home))
        }
    }

    var filteredItems: [FileItem] {
        if searchQuery.isEmpty {
            return items
        }
        return items.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
    }

    var canGoBack: Bool { currentIndex > 0 }
    var canGoForward: Bool { currentIndex < navigationStack.count - 1 }
    var canGoUp: Bool { currentDirectory?.url.path != "/" }

    var selectedItems: [FileItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    func sortedItems(using sortOrder: [KeyPathComparator<FileItem>]) -> [FileItem] {
        return filteredItems.sorted(using: sortOrder)
    }

    func navigateToDirectory(_ item: FileItem) {
        guard item.isDirectory else { return }
        currentDirectory = item
        do {
            items = try fileService.listContents(of: item.url)
            navigationStack = Array(navigationStack.prefix(currentIndex + 1))
            navigationStack.append(item)
            currentIndex = navigationStack.count - 1
            selectedItemIDs.removeAll()
        } catch {
            print("Error listing contents: \(error)")
        }
    }

    func goBack() {
        guard canGoBack else { return }
        currentIndex -= 1
        navigateToDirectory(navigationStack[currentIndex])
    }

    func goForward() {
        guard canGoForward else { return }
        currentIndex += 1
        navigateToDirectory(navigationStack[currentIndex])
    }

    func goUp() {
        guard canGoUp, let dir = currentDirectory else { return }
        let parent = FileItem(url: dir.url.deletingLastPathComponent())
        navigateToDirectory(parent)
    }

    func createFile(name: String) {
        guard let dir = currentDirectory else { return }
        do {
            let item = try fileService.createFile(at: dir.url, name: name)
            items.append(item)
        } catch {
            print("Error creating file: \(error)")
        }
    }

    func createDirectory(name: String) {
        guard let dir = currentDirectory else { return }
        do {
            let item = try fileService.createDirectory(at: dir.url, name: name)
            items.append(item)
        } catch {
            print("Error creating directory: \(error)")
        }
    }

    func deleteItems(_ itemsToDelete: [FileItem]) {
        for item in itemsToDelete {
            do {
                try fileService.deleteFile(at: item.url)
                items.removeAll { $0.id == item.id }
            } catch {
                print("Error deleting \(item.name): \(error)")
            }
        }
        selectedItemIDs.removeAll()
    }

    func renameItem(_ item: FileItem, to newName: String) {
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileService.moveFile(from: item.url, to: newURL)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = FileItem(url: newURL)
            }
        } catch {
            print("Error renaming: \(error)")
        }
    }

    func handleDrop(_ urls: [URL]) {
        guard let destDir = currentDirectory?.url else { return }
        for url in urls {
            let destURL = destDir.appendingPathComponent(url.lastPathComponent)
            do {
                try fileService.moveFile(from: url, to: destURL)
            } catch {
                print("Error moving \(url): \(error)")
            }
        }
        navigateToDirectory(currentDirectory!)
    }
}