import SwiftUI

struct ExplorerWindowView: View {
    @StateObject var viewModel = ExplorerViewModel()
    @State private var showViewOptions = false
    @State private var showSharingPicker = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    SidebarView(viewModel: viewModel)
                    ContentAreaView(viewModel: viewModel)
                }
                StatusBarView(viewModel: viewModel)
            }
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert, presenting: viewModel.errorMessage)
        { _ in
            Button("OK") {
                viewModel.errorMessage = nil
                viewModel.showErrorAlert = false
            }
        } message: { message in
            Text(message)
        }
        .background(
            SharingServicePickerView(
                urls: viewModel.selectedFiles.compactMap { selectedFileId in
                    viewModel.filteredFiles.first(where: { $0.id == selectedFileId }).flatMap {
                        viewModel.fileURL(for: $0)
                    }
                },
                isPresented: $showSharingPicker
            )
        )
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack {
                    Spacer()
                    Text(viewModel.currentFolderURL.lastPathComponent)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
                .frame(width: 180)
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 12) {
                    Button(action: { viewModel.goBack() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(viewModel.canGoBack ? .white : .gray)
                    }
                    .disabled(!viewModel.canGoBack)
                    Button(action: { viewModel.goForward() }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(viewModel.canGoForward ? .white : .gray)
                    }
                    .disabled(!viewModel.canGoForward)
                    Button(action: { viewModel.quickLook() }) {
                        Image(systemName: "eye")
                    }
                    Button(action: { viewModel.newTab() }) {
                        Image(systemName: "square.on.square")
                    }
                    Button(action: { viewModel.trash() }) {
                        Image(systemName: "trash")
                    }
                    .disabled(viewModel.selectedFiles.isEmpty)
                    Button(action: {
                        let urls = viewModel.selectedFiles.compactMap { selectedFileId in
                            viewModel.filteredFiles.first(where: { $0.id == selectedFileId })
                                .flatMap { viewModel.fileURL(for: $0) }
                        }
                        if !urls.isEmpty {
                            showSharingPicker = true
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: { showViewOptions.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .popover(isPresented: $showViewOptions) {
                        ViewOptionsPopover(viewModel: viewModel)
                    }
                    Button(action: { viewModel.toggleViewMode() }) {
                        Image(
                            systemName: viewModel.viewMode == .list
                                ? "square.grid.2x2" : "list.bullet")
                    }
                    Menu {
                        Button("New Folder", action: viewModel.createNewFolder)
                        Button("New File", action: viewModel.createNewFile)
                        Divider()
                        Button("Copy", action: viewModel.copySelectedFiles)
                        Button("Duplicate", action: viewModel.duplicateSelectedFiles)
                        Button(
                            "Rename",
                            action: {
                                if let selectedFileId = viewModel.selectedFiles.first,
                                    let file = viewModel.filteredFiles.first(where: {
                                        $0.id == selectedFileId
                                    })
                                {
                                    viewModel.startRenaming(file)
                                }
                            }
                        )
                        .disabled(viewModel.selectedFiles.isEmpty)
                        Divider()
                        Button("Get Info", action: viewModel.showGetInfo)
                            .disabled(viewModel.selectedFiles.isEmpty)
                        Button("Compress", action: viewModel.compressSelectedFiles)
                            .disabled(viewModel.selectedFiles.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    Spacer(minLength: 12)
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .frame(minWidth: 120, maxWidth: .infinity)
                    }
                    .padding(6)
                    .background(.thinMaterial)
                }
            }
        }
    }
}

// WindowAccessor to get NSWindow for customization
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct ViewOptionsPopover: View {
    @ObservedObject var viewModel: ExplorerViewModel

    var body: some View {
        Form {
            Section("Display Options") {
                Toggle("Show Hidden Files", isOn: $viewModel.showHiddenFiles)
                    .onChange(of: viewModel.showHiddenFiles) { _, newValue in
                        viewModel.toggleHiddenFiles(newValue)
                    }
            }

            Section("Layout") {
                Slider(value: $viewModel.iconSize, in: 32...128, step: 16) {
                    Text("Icon Size")
                }
                Text("\(Int(viewModel.iconSize)) pt")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Sorting") {
                Picker("Sort By", selection: $viewModel.sortColumn) {
                    Text("Name").tag(FileSortColumn.name)
                    Text("Size").tag(FileSortColumn.size)
                    Text("Date Modified").tag(FileSortColumn.dateAdded)
                    Text("Kind").tag(FileSortColumn.kind)
                }
                .pickerStyle(.menu)

                Toggle("Ascending", isOn: $viewModel.sortAscending)
                    .onChange(of: viewModel.sortAscending) { _, _ in
                        viewModel.applySorting()
                    }
            }
        }
        .frame(width: 280)
        .padding()
    }
}

struct SharingServicePickerView: NSViewRepresentable {
    let urls: [URL]
    @Binding var isPresented: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.frame = NSRect(x: 0, y: 0, width: 1, height: 1)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented && !urls.isEmpty {
            let picker = NSSharingServicePicker(items: urls)
            picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
            DispatchQueue.main.async {
                self.isPresented = false
            }
        }
    }
}

#Preview {
    ExplorerWindowView()
}
