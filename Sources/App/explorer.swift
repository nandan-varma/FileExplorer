
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
				       .frame(minWidth: 900, minHeight: 600)
				       .background(Color.clear)
		       }
		       Settings {
			       EmptyView()
		       }
	       }
}
