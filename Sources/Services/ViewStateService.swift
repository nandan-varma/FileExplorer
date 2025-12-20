import Foundation

class ViewStateService: ObservableObject {
    @Published var viewMode: ViewMode = .list
    @Published var showHiddenFiles: Bool = false
    @Published var iconSize: Double = 64

    func toggleViewMode() {
        viewMode = viewMode == .list ? .grid : .list
    }

    func toggleHiddenFiles(_ show: Bool) {
        showHiddenFiles = show
    }

    func setIconSize(_ size: Double) {
        iconSize = size
    }
}