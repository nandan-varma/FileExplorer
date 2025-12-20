import Cocoa
import SwiftUI

class CustomWindowController: NSWindowController, NSWindowDelegate {
    convenience init<Content: View>(rootView: Content) {
        let hosting = NSHostingView(rootView: rootView)
        let window = NSWindow(contentViewController: NSViewController())
        window.contentView = hosting
        window.setContentSize(NSSize(width: 1024, height: 700))
        window.styleMask = [
            .titled, .closable, .miniaturizable, .resizable
        ]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = NSColor.windowBackgroundColor
        window.center()
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        window.delegate = nil
        self.init(window: window)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.cornerRadius = 16
        window?.backgroundColor = .clear
    }
}

extension NSWindow {
    var cornerRadius: CGFloat {
        get { return 0 }
        set {
            contentView?.wantsLayer = true
            contentView?.layer?.cornerRadius = newValue
            contentView?.layer?.masksToBounds = true
        }
    }
}
