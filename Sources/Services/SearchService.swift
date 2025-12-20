import Foundation

class SearchService: ObservableObject {
    @Published var searchText: String = ""
    @Published var filteredFiles: [FileItem] = []
    private(set) var allFiles: [FileItem] = []
    private var searchDebounceTimer: Timer?

    // MARK: - Search Operations
    func setFiles(_ files: [FileItem]) {
        allFiles = files
        performSearch(searchText)
    }

    func updateSearch(_ text: String, from files: [FileItem]) {
        searchDebounceTimer?.invalidate()
        searchText = text
        allFiles = files

        searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.performSearch(text)
        }
    }

    func clearSearch() {
        searchText = ""
        filteredFiles = allFiles
    }

    // MARK: - Private Methods
    private func performSearch(_ text: String) {
        if text.isEmpty {
            filteredFiles = allFiles
        } else {
            filteredFiles = allFiles.filter { file in
                file.name.lowercased().contains(text.lowercased())
            }
        }
    }
}