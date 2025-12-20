
import AppKit
import FullDiskAccess

@MainActor
func requestFullDiskAccessIfNeeded() {
    if !FullDiskAccess.isGranted {
        FullDiskAccess.promptIfNotGranted(
            title: "Enable Full Disk Access for Explorer",
            message: "Explorer requires Full Disk Access to browse all folders and files on your Mac.",
            settingsButtonTitle: "Open Settings",
            skipButtonTitle: "Later",
            skipHandler: { print("User skipped permission screen!") },
            canBeSuppressed: false,
            icon: nil
        )
    }
}
