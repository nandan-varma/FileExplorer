import SwiftUI
import AppKit
import QuickLook
import FullDiskAccess

struct FileRow: View {
    let file: URL
    @Binding var selectedFile: URL?
    let onOpen: (URL) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: getIcon(for: file))
                .resizable()
                .frame(width: 20, height: 20)
            Text(file.lastPathComponent)
                .font(.system(size: 14))
        }
        .padding(.vertical, 4)
        .listRowBackground(selectedFile == file ? Color.accentColor.opacity(0.3) : Color.clear)
        .onTapGesture {
            selectedFile = file
        }
        .onTapGesture(count: 2) {
            if file.hasDirectoryPath {
                onOpen(file)
            }
        }
    }

    private func getIcon(for url: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

struct ContentView: View {
    @State private var currentDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    @State private var files: [URL] = []
    @State private var selectedFile: URL?
    @State private var quickLookURL: URL?

    var body: some View {
        if FullDiskAccess.isGranted {
            NavigationSplitView {
                ScrollViewReader { proxy in
                    List(selection: $selectedFile) {
                        ForEach(files, id: \.self) { file in
                            FileRow(file: file, selectedFile: $selectedFile, onOpen: { url in
                                currentDirectory = url
                                selectedFile = nil
                                loadFiles()
                            })
                            .id(file)
                        }
                    }
                        .onChange(of: selectedFile) { oldValue, newValue in
                            if let file = newValue {
                                withAnimation {
                                    proxy.scrollTo(file, anchor: .center)
                                }
                            }
                        }
                }
                .navigationTitle(currentDirectory.path)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            currentDirectory = currentDirectory.deletingLastPathComponent()
                            selectedFile = nil
                            loadFiles()
                        }) {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .disabled(currentDirectory.path == "/" || currentDirectory.path == FileManager.default.homeDirectoryForCurrentUser.path)
                    }
                }
                .onAppear {
                    loadFiles()
                }
                .onKeyPress(.space) {
                    if let selectedFile = selectedFile {
                        quickLookURL = selectedFile
                    }
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    if let currentIndex = files.firstIndex(of: selectedFile ?? URL(fileURLWithPath: "")) {
                        let newIndex = max(0, currentIndex - 1)
                        selectedFile = files[newIndex]
                    } else if !files.isEmpty {
                        selectedFile = files.last
                    }
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    if let currentIndex = files.firstIndex(of: selectedFile ?? URL(fileURLWithPath: "")) {
                        let newIndex = min(files.count - 1, currentIndex + 1)
                        selectedFile = files[newIndex]
                    } else if !files.isEmpty {
                        selectedFile = files.first
                    }
                    return .handled
                }
                .onKeyPress(.return) {
                    if let file = selectedFile, file.hasDirectoryPath {
                        currentDirectory = file
                        selectedFile = nil
                        loadFiles()
                    }
                    return .handled
                }
                .quickLookPreview($quickLookURL)
            } detail: {
                if let selectedFile = selectedFile {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("File Preview")
                            .font(.title2)
                            .padding(.bottom, 8)
                        Text("Name: \(selectedFile.lastPathComponent)")
                            .font(.system(size: 14))
                        Text("Type: \(selectedFile.pathExtension.isEmpty ? "Folder" : selectedFile.pathExtension.uppercased())")
                            .font(.system(size: 14))
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: selectedFile.path),
                           let size = attributes[.size] as? Int64 {
                            Text("Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                                .font(.system(size: 14))
                        }
                        Spacer()
                    }
                    .padding(20)
                } else {
                    Text("Select a file to preview")
                        .foregroundColor(.secondary)
                }
            }
        } else {
            VStack {
                Text("Full Disk Access is required to browse files.")
                Button("Open System Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                }
            }
        }
    }

    private func loadFiles() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: nil)
            files = contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
            // Clear selection if selected file is not in current directory
            if let selected = selectedFile, !files.contains(selected) {
                selectedFile = nil
            }
        } catch {
            print("Error loading files: \(error)")
            files = []
            selectedFile = nil
        }
    }


}