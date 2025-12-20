import SwiftUI

@main
struct ExplorerApp: App {
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
