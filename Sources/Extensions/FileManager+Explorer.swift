import Foundation

extension FileManager {
    func explorerContentsOfDirectory(at url: URL) throws -> [URL] {
        let contents = try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
    }
}