import Foundation
import AppKit

class FileSystemService: ObservableObject {
    private let fileManager = FileManager.default

    // MARK: - File Loading
    func loadFiles(at url: URL, showHiddenFiles: Bool = false, completion: @escaping (Result<[FileItem], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let options: FileManager.DirectoryEnumerationOptions = showHiddenFiles ? [] : [.skipsHiddenFiles]
                let contents = try self.fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                    options: options
                )

                let fileItems = contents.map { fileURL in
                    let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
                    let isFolder = resourceValues?.isDirectory ?? false
                    let sizeBytes = resourceValues?.fileSize.map { Int64($0) }
                    let size = isFolder ? nil : sizeBytes.flatMap { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
                    let kind = isFolder ? "Folder" : fileURL.pathExtension.uppercased()
                    let dateModified = resourceValues?.contentModificationDate
                    let dateAdded = dateModified.map { Self.dateFormatter.string(from: $0) }

                    return FileItem(
                        name: fileURL.lastPathComponent,
                        size: size,
                        sizeBytes: sizeBytes,
                        kind: kind,
                        dateAdded: dateAdded,
                        dateModified: dateModified,
                        isFolder: isFolder,
                        expanded: false
                    )
                }

                DispatchQueue.main.async {
                    completion(.success(fileItems))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - File Operations
    func createNewFolder(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let baseName = "Untitled Folder"
        var folderName = baseName
        var counter = 1

        while fileManager.fileExists(atPath: url.appendingPathComponent(folderName).path) {
            folderName = "\(baseName) \(counter)"
            counter += 1
        }

        let folderURL = url.appendingPathComponent(folderName)

        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func createNewFile(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let baseName = "Untitled.txt"
        var fileName = baseName
        var counter = 1

        while fileManager.fileExists(atPath: url.appendingPathComponent(fileName).path) {
            let nameWithoutExtension = "Untitled \(counter)"
            fileName = "\(nameWithoutExtension).txt"
            counter += 1
        }

        let fileURL = url.appendingPathComponent(fileName)

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func renameFile(at oldURL: URL, to newURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try fileManager.moveItem(at: oldURL, to: newURL)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func duplicateFiles(_ urls: [URL], completion: @escaping (Result<Void, Error>) -> Void) {
        for url in urls {
            let duplicateName = generateDuplicateName(for: url)
            let duplicateURL = url.deletingLastPathComponent().appendingPathComponent(duplicateName)

            do {
                try fileManager.copyItem(at: url, to: duplicateURL)
            } catch {
                completion(.failure(error))
                return
            }
        }
        completion(.success(()))
    }

    func trashFiles(_ urls: [URL], completion: @escaping (Result<Void, Error>) -> Void) {
        for url in urls {
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            } catch {
                completion(.failure(error))
                return
            }
        }
        completion(.success(()))
    }

    func compressFiles(_ urls: [URL], completion: @escaping (Result<Void, Error>) -> Void) {
        guard !urls.isEmpty else {
            completion(.success(()))
            return
        }

        let tempDir = fileManager.temporaryDirectory
        let archiveName = "Archive.zip"
        let archiveURL = tempDir.appendingPathComponent(archiveName)

        // Remove existing archive if it exists
        try? fileManager.removeItem(at: archiveURL)

        do {
            // Create zip archive using Process
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.arguments = ["-r", archiveURL.path] + urls.map { $0.path }

            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                // Move archive to current directory
                let destinationURL = urls.first!.deletingLastPathComponent().appendingPathComponent(archiveName)
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: archiveURL, to: destinationURL)
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "CompressionError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to create zip archive"])))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func copyFilesToPasteboard(_ urls: [URL]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(urls as [NSPasteboardWriting])
    }

    // MARK: - Validation
    func isValidFileURL(_ url: URL) -> Bool {
        guard url.scheme == "file" else { return false }

        let path = url.path
        guard !path.contains("../") && !path.contains("..\\") else { return false }

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    // MARK: - Private Helpers
    private func generateDuplicateName(for url: URL) -> String {
        let fileName = url.lastPathComponent
        let baseName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        var duplicateName = fileName
        var counter = 1

        while fileManager.fileExists(atPath: url.deletingLastPathComponent().appendingPathComponent(duplicateName).path) {
            if fileExtension.isEmpty {
                duplicateName = "\(baseName) \(counter)"
            } else {
                duplicateName = "\(baseName) \(counter).\(fileExtension)"
            }
            counter += 1
        }

        return duplicateName
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}