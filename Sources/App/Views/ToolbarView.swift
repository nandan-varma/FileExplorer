import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: FileExplorerViewModel
    @State private var showCreateFile = false
    @State private var showCreateFolder = false
    @State private var newName = ""

    var body: some View {
        HStack {
            Button(action: viewModel.goUp) {
                Image(systemName: "chevron.up")
            }
            .disabled(!viewModel.canGoUp)

            Button(action: viewModel.goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.canGoBack)

            Button(action: viewModel.goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.canGoForward)

            Button("New File") {
                newName = ""
                showCreateFile = true
            }

            Button("New Folder") {
                newName = ""
                showCreateFolder = true
            }

            Picker("View Mode", selection: $viewModel.viewMode) {
                Text("List").tag(ViewMode.list)
                Text("Icon").tag(ViewMode.icon)
                Text("Column").tag(ViewMode.column)
            }
            .pickerStyle(.segmented)

            TextField("Search", text: $viewModel.searchQuery)
                .textFieldStyle(.roundedBorder)

            Spacer()

            if let dir = viewModel.currentDirectory {
                Text(dir.name)
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .sheet(isPresented: $showCreateFile) {
            CreateDialog(title: "New File", name: $newName, onCreate: {
                viewModel.createFile(name: newName)
                showCreateFile = false
            }, onCancel: { showCreateFile = false })
        }
        .sheet(isPresented: $showCreateFolder) {
            CreateDialog(title: "New Folder", name: $newName, onCreate: {
                viewModel.createDirectory(name: newName)
                showCreateFolder = false
            }, onCancel: { showCreateFolder = false })
        }
    }
}

struct CreateDialog: View {
    let title: String
    @Binding var name: String
    let onCreate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Text(title)
            TextField("Name", text: $name)
            HStack {
                Button("Cancel", action: onCancel)
                Button("Create", action: onCreate)
                    .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}