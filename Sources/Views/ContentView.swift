import SwiftUI
import AppKit
import QuickLook
import FullDiskAccess

struct ContentView: View {
    @State private var viewModel = FileExplorerViewModel()

    var body: some View {
        if FullDiskAccess.isGranted {
            FinderWindowView(viewModel: viewModel)
                .onAppear {
                    viewModel.loadFiles()
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
}