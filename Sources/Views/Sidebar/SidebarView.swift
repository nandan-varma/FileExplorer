
import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ExplorerViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Recents/Shared
            Group {
                SidebarSectionHeader(title: " ")
                SidebarItem(icon: "clock", label: "Recents", selected: viewModel.selectedSidebarItem == .recents) {
                    viewModel.selectSidebarItem(.recents)
                }
                SidebarItem(icon: "person.2", label: "Shared", selected: viewModel.selectedSidebarItem == .shared) {
                    viewModel.selectSidebarItem(.shared)
                }
            }
            // Favorites
            SidebarSectionHeader(title: "FAVORITES")
            ForEach([SidebarItemType.applications, .documents, .desktop, .downloads, .pictures], id: \.self) { item in
                SidebarItem(icon: "folder", label: item.label, selected: viewModel.selectedSidebarItem == item) {
                    viewModel.selectSidebarItem(item)
                }
            }
            // User Home
            SidebarSectionHeader(title: " ")
            SidebarItem(icon: "house", label: SidebarItemType.nandan.label, selected: viewModel.selectedSidebarItem == .nandan) {
                viewModel.selectSidebarItem(.nandan)
            }
            SidebarItem(icon: "folder", label: SidebarItemType.dev.label, selected: viewModel.selectedSidebarItem == .dev) {
                viewModel.selectSidebarItem(.dev)
            }
            // Locations
            SidebarSectionHeader(title: "LOCATIONS")
            SidebarItem(icon: "icloud", label: SidebarItemType.icloud.label, selected: viewModel.selectedSidebarItem == .icloud) {
                viewModel.selectSidebarItem(.icloud)
            }
            SidebarItem(icon: "house", label: SidebarItemType.home.label, selected: viewModel.selectedSidebarItem == .home) {
                viewModel.selectSidebarItem(.home)
            }
            SidebarItem(icon: "laptopcomputer", label: SidebarItemType.macbook.label, selected: viewModel.selectedSidebarItem == .macbook) {
                viewModel.selectSidebarItem(.macbook)
            }
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 240, maxWidth: 260)
        .background(Color.black.opacity(0.7))
    }
}

struct SidebarSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.gray)
            .padding(.top, 16)
            .padding(.bottom, 4)
            .padding(.horizontal, 12)
    }
}

struct SidebarItem: View {
    let icon: String
    let label: String
    var selected: Bool = false
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 18)
                    .foregroundColor(selected ? .white : .gray)
                Text(label)
                    .foregroundColor(selected ? .white : .gray)
                    .fontWeight(selected ? .semibold : .regular)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if selected {
                        Color.blue.cornerRadius(8)
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SidebarView(viewModel: ExplorerViewModel())
}
