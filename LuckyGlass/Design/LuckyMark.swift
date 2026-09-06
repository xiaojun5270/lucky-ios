import SwiftUI

/// The Lucky brand mark supplied with the native app.
struct LuckyMark: View {
    var size: CGFloat = 82
    /// Kept for compatibility with the existing call sites.
    var plate: Bool = true

    var body: some View {
        Image("LuckyMark")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Lucky")
    }
}
