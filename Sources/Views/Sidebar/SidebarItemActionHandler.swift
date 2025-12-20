import SwiftUI

struct SidebarItemActionHandler: ViewModifier {
    let onSelect: () -> Void
    let onOpen: () -> Void
    let onQuickLook: () -> Void
    let onCommandClick: () -> Void

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                onSelect()
            }
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                onOpen()
            })
            // Space key for Quick Look (requires custom key handling)
            .modifier(CommandClickGesture(onCommandClick: onCommandClick))
    }
}

struct CommandClickGesture: ViewModifier {
    let onCommandClick: () -> Void
    func body(content: Content) -> some View {
        content.gesture(
            TapGesture().modifiers(.command).onEnded {
                onCommandClick()
            }
        )
    }
}

extension View {
    func sidebarItemActions(
        onSelect: @escaping () -> Void,
        onOpen: @escaping () -> Void,
        onQuickLook: @escaping () -> Void,
        onCommandClick: @escaping () -> Void
    ) -> some View {
        self.modifier(SidebarItemActionHandler(
            onSelect: onSelect,
            onOpen: onOpen,
            onQuickLook: onQuickLook,
            onCommandClick: onCommandClick
        ))
    }
}
