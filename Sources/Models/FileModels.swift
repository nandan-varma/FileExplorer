import Foundation

struct FileItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let size: String?
    let sizeBytes: Int64?
    let kind: String?
    let dateAdded: String?
    let dateModified: Date?
    let isFolder: Bool
    let expanded: Bool
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
        case .macbook: return "Nandan's MacBook Air"
        }
    }
}

enum FileSortColumn {
    case name, size, kind, dateAdded
}

enum ViewMode {
    case list, grid
}