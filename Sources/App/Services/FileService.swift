import Foundation

protocol FileService {
    func listContents(of directory: URL) throws -> [FileItem]
    func createFile(at url: URL, name: String) throws -> FileItem
    func createDirectory(at url: URL, name: String) throws -> FileItem
    func deleteFile(at url: URL) throws
    func moveFile(from: URL, to: URL) throws
}