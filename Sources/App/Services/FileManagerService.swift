import Foundation

struct FileManagerService: FileService {
    func listContents(of directory: URL) throws -> [FileItem] {
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: .skipsHiddenFiles)
        return contents.map(FileItem.init)
    }

    func createFile(at url: URL, name: String) throws -> FileItem {
        let fileURL = url.appendingPathComponent(name)
        try Data().write(to: fileURL)
        return FileItem(url: fileURL)
    }

    func createDirectory(at url: URL, name: String) throws -> FileItem {
        let dirURL = url.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: false)
        return FileItem(url: dirURL)
    }

    func deleteFile(at url: URL) throws {
        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    func moveFile(from: URL, to: URL) throws {
        try FileManager.default.moveItem(at: from, to: to)
    }
}