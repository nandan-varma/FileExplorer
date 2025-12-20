import SwiftUI

extension View {
    @ViewBuilder
    func macLiquidGlass() -> some View {
        self.glassEffect(.regular)
            .clipShape(Rectangle())
    }
}
