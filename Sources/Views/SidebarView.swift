import SwiftUI
import AppKit

struct SidebarView: View {
    @ObservedObject var viewModel: FileExplorerViewModel

    var body: some View {
        List {
            Section {
                Button(action: { /* Recents placeholder */ }) {
                    Label("Recents", systemImage: "clock")
                }
                Button(action: { /* Shared placeholder */ }) {
                    Label("Shared", systemImage: "folder.badge.person.crop")
                }
            }

            Section("Favorites") {
                ForEach(viewModel.favorites, id: \.self) { url in
                    Button(action: {
                        viewModel.navigateToDirectory(url)
                    }) {
                        Label(url.lastPathComponent, systemImage: iconForURL(url))
                            .foregroundColor(viewModel.currentDirectory == url ? .blue : .primary)
                    }
                }
            }

            Section {
                let home = FileManager.default.homeDirectoryForCurrentUser
                Button(action: {
                    viewModel.navigateToDirectory(home)
                }) {
                    Label(home.lastPathComponent, systemImage: "house")
                }
                // Placeholder for dev or other subdirs
                Button(action: { /* dev placeholder */ }) {
                    Label("dev", systemImage: "folder")
                }
            }

            Section("Locations") {
                Button(action: { /* iCloud placeholder */ }) {
                    Label("iCloud Drive", systemImage: "icloud")
                }
                let home = FileManager.default.homeDirectoryForCurrentUser
                Button(action: {
                    viewModel.navigateToDirectory(home)
                }) {
                    Label(home.lastPathComponent, systemImage: "house")
                }
                Button(action: {
                    viewModel.navigateToDirectory(URL(fileURLWithPath: "/"))
                }) {
                    Label("Nandan’s MacBook Air", systemImage: "laptopcomputer")
                }
            }
        }
        .frame(minWidth: 200)
        .listStyle(.sidebar)
    }

    private func iconForURL(_ url: URL) -> String {
        switch url.lastPathComponent {
        case "Applications": return "app.badge"
        case "Documents": return "doc.on.doc"
        case "Desktop": return "desktopcomputer"
        case "Downloads": return "arrow.down.circle"
        case "Pictures": return "photo.on.rectangle"
        default: return "folder"
        }
    }
}