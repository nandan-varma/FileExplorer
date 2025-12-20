
import SwiftUI
import AppKit

@main
struct ExplorerApp: App {
	init() {
		requestFullDiskAccessIfNeeded()
	}
	var body: some Scene {
		WindowGroup {
			ExplorerWindowView()
		}
		.windowStyle(.hiddenTitleBar)
		Settings {
			EmptyView()
		}
	}
}
