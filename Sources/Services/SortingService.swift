import Foundation

class SortingService: ObservableObject {
    @Published var sortColumn: FileSortColumn = .dateAdded
    @Published var sortAscending: Bool = false

    func sort(by column: FileSortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
    }

    func applySorting(to files: [FileItem]) -> [FileItem] {
        return files.sorted { lhs, rhs in
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
}