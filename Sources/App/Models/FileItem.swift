import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    var name: String { url.lastPathComponent }
    let size: Int64?
    let modifiedDate: Date?
    let creationDate: Date?
    let isDirectory: Bool
    var fileExtension: String { url.pathExtension }

    init(url: URL) {
        self.url = url
        self.isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey])
        if let fileSize = values?.fileSize {
            self.size = Int64(fileSize)
        } else {
            self.size = nil
        }
        self.modifiedDate = values?.contentModificationDate
        self.creationDate = values?.creationDate
    }
}