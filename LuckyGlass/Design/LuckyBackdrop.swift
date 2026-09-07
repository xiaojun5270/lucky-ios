import SwiftUI

/// The neutral workspace behind every screen.
struct LuckyBackdrop: View {
    /// Kept for source compatibility with the login screen. The new workspace is intentionally
    /// still so controls and live metrics carry all of the visual emphasis.
    var animated: Bool = false

    var body: some View {
        LuckyTheme.canvasTop
        .ignoresSafeArea()
    }
}
