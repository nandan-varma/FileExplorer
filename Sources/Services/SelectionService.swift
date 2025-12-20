import Foundation

class SelectionService: ObservableObject {
    @Published var selectedFile: FileItem.ID? = nil
    @Published var selectedFiles: Set<FileItem.ID> = []

    // MARK: - Selection Operations
    func selectFile(_ file: FileItem) {
        selectedFile = file.id
        selectedFiles = [file.id]
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

    func isFileSelected(_ file: FileItem) -> Bool {
        return selectedFiles.contains(file.id)
    }

    func isFilePrimarySelected(_ file: FileItem) -> Bool {
        return selectedFile == file.id
    }

    // MARK: - Selection Queries
    func getSelectedFiles(from files: [FileItem]) -> [FileItem] {
        return files.filter { selectedFiles.contains($0.id) }
    }

    func getPrimarySelectedFile(from files: [FileItem]) -> FileItem? {
        guard let selectedId = selectedFile else { return nil }
        return files.first { $0.id == selectedId }
    }

    func hasSelection() -> Bool {
        return !selectedFiles.isEmpty
    }

    func selectionCount() -> Int {
        return selectedFiles.count
    }

    // MARK: - Navigation in Selection
    func selectNextFile(from files: [FileItem]) {
        guard !files.isEmpty else { return }

        let currentIndex: Int
        if let selectedId = selectedFile,
           let index = files.firstIndex(where: { $0.id == selectedId }) {
            currentIndex = index
        } else if !files.isEmpty {
            currentIndex = 0
        } else {
            return
        }

        let nextIndex = (currentIndex + 1) % files.count
        let nextFile = files[nextIndex]
        selectFile(nextFile)
    }

    func selectPreviousFile(from files: [FileItem]) {
        guard !files.isEmpty else { return }

        let currentIndex: Int
        if let selectedId = selectedFile,
           let index = files.firstIndex(where: { $0.id == selectedId }) {
            currentIndex = index
        } else if !files.isEmpty {
            currentIndex = files.count - 1
        } else {
            return
        }

        let prevIndex = currentIndex == 0 ? files.count - 1 : currentIndex - 1
        let prevFile = files[prevIndex]
        selectFile(prevFile)
    }
}