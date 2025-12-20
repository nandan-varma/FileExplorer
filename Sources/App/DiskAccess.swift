import AppKit

@MainActor
func requestFullDiskAccessIfNeeded() {
    let openPanel = NSOpenPanel()
    openPanel.message = "Please grant access to your home folder to enable file browsing."
    openPanel.prompt = "Grant Access"
    openPanel.canChooseFiles = false
    openPanel.canChooseDirectories = true
    openPanel.allowsMultipleSelection = false
    openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
    openPanel.begin { response in
        if response == .OK, let url = openPanel.url {
            // Start accessing security-scoped resource
            _ = url.startAccessingSecurityScopedResource()
            // Store bookmark for future launches if needed
        }
    }
}
