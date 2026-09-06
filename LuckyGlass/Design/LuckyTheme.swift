import SwiftUI
import UIKit

/// The design language for LuckyGlass.
///
/// The original is a React Native admin panel with flat cards and system blue accents. This port
/// deliberately does not copy that look: it uses one ambient "aurora" backdrop, a teal/violet brand
/// pair, rounded numerics, and concentric corners so every surface nests correctly under iOS 26's
/// glass chrome. Only the *copy* is carried over verbatim.
///
/// Everything here is a token. Screens must not hard-code colours, radii or durations — a value
/// that appears twice belongs in this file.
enum LuckyTheme {
    // MARK: - Palette

    /// Light/dark pairs without an asset catalog. `UIColor`'s dynamic provider is resolved per
    /// trait collection, so a single `Color` adapts to appearance, Increase Contrast and vibrancy.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
        })
    }

    /// Brand teal. Reserved for the primary action and the selected state — per Apple's guidance a
    /// glass tint conveys meaning, so it must stay rare.
    static let accent = dynamic(light: 0x0E9C93, dark: 0x2ED3C6)
    /// The accent at fill strength, for chips and gauge tracks.
    static let accentSoft = dynamic(light: 0xD6F5F1, dark: 0x123E3B)
    /// Secondary brand hue, used for Docker and tunnelling accents.
    static let violet = dynamic(light: 0x5B4BDB, dark: 0x9A8CFF)
    static let violetSoft = dynamic(light: 0xE6E2FF, dark: 0x241F4D)

    static let success = dynamic(light: 0x11845B, dark: 0x34D399)
    static let successSoft = dynamic(light: 0xD8F3E7, dark: 0x0F3A2C)
    static let warning = dynamic(light: 0xA35B00, dark: 0xF5A524)
    static let warningSoft = dynamic(light: 0xFCEBD2, dark: 0x40300E)
    static let danger = dynamic(light: 0xC0304C, dark: 0xFF6B85)
    static let dangerSoft = dynamic(light: 0xFCE3E8, dark: 0x451C25)
    static let info = dynamic(light: 0x2C6BD8, dark: 0x74A8FF)
    static let infoSoft = dynamic(light: 0xDDE9FF, dark: 0x18294D)
    static let idle = dynamic(light: 0x6B7280, dark: 0x9AA3B2)
    static let idleSoft = dynamic(light: 0xECEEF2, dark: 0x232833)

    // MARK: - Backdrop and surfaces

    /// The two ends of the page wash. Kept low-contrast: glass needs something to refract, but a
    /// busy backdrop makes text on the floating layer illegible.
    static let canvasTop = dynamic(light: 0xF6F8FA, dark: 0x0B0E13)
    static let canvasBottom = dynamic(light: 0xEDF1F5, dark: 0x11151C)
    /// The two aurora blooms. Alpha is applied at use, so these stay opaque here.
    static let bloomTeal = dynamic(light: 0x38D6C6, dark: 0x1E9C93)
    static let bloomViolet = dynamic(light: 0x8B7DF7, dark: 0x4B3FA8)

    /// Content-layer card fill. Nearly opaque — cards live *under* the glass chrome and must never
    /// be glass themselves.
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x171B23)
    /// A second level for rows nested inside a card.
    static let surfaceRaised = dynamic(light: 0xF4F6F9, dark: 0x1F242E)
    /// Code, JSON and log backgrounds.
    static let surfaceSunken = dynamic(light: 0xF0F2F6, dark: 0x0E1218)
    static let hairline = dynamic(light: 0xE3E7EC, dark: 0x2A303B)
    static let separator = dynamic(light: 0xEDEFF3, dark: 0x232935)

    static let textPrimary = dynamic(light: 0x111827, dark: 0xF2F5F9)
    static let textSecondary = dynamic(light: 0x525C6B, dark: 0xA8B2C1)
    static let textTertiary = dynamic(light: 0x8A94A3, dark: 0x6F7987)
    /// Text on top of a filled accent surface.
    static let textOnAccent = dynamic(light: 0xFFFFFF, dark: 0x04211F)

    // MARK: - Radii

    /// Corner radii, outermost first. Concentric corners require the inner radius to be the outer
    /// radius minus the padding between them, which `ConcentricRectangle` derives from the
    /// container shape — these constants are the *outer* values.
    enum Radius {
        static let hero: CGFloat = 30
        static let card: CGFloat = 22
        static let panel: CGFloat = 18
        static let row: CGFloat = 14
        static let chip: CGFloat = 11
        static let field: CGFloat = 14
        /// Floor passed to `.concentric(minimum:)` so a nested corner never collapses to a square.
        static let concentricFloor: CGFloat = 8
    }

    // MARK: - Spacing

    enum Space {
        static let hair: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        /// Page side margin. Also the spacing handed to `GlassEffectContainer`, which uses it to
        /// decide how close two glass shapes must be before their fields merge.
        static let gutter: CGFloat = 18
        /// Vertical rhythm between cards in a scroll view.
        static let stack: CGFloat = 14
        /// Inner padding of a card, and therefore the concentric inset of anything drawn inside
        /// one.
        static let cardInset: CGFloat = 16
    }

    // MARK: - Typography

    /// Rounded throughout. The port shows a lot of numbers — ports, byte counts, durations — and
    /// rounded digits read as data rather than as prose.
    enum Text {
        static let hero = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let sectionTitle = Font.system(size: 13, weight: .semibold, design: .rounded)
        static let cardTitle = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 15, weight: .regular, design: .rounded)
        static let bodyMedium = Font.system(size: 15, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let captionMedium = Font.system(size: 12, weight: .semibold, design: .rounded)
        static let label = Font.system(size: 13, weight: .medium, design: .rounded)
        /// The big number in a metric tile.
        static let metric = Font.system(size: 26, weight: .semibold, design: .rounded)
        static let metricSmall = Font.system(size: 19, weight: .semibold, design: .rounded)
        /// JSON, logs and paths. Monospaced digits alone are not enough — these need fixed advance.
        static let code = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let codeSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
        static let button = Font.system(size: 15, weight: .semibold, design: .rounded)
    }

    // MARK: - Motion

    /// Glass morphing (`glassEffectID`) only interpolates inside `withAnimation`, so these are the
    /// durations the whole app shares. Anything faster than `.snap` reads as a glitch on a shape
    /// that is also refracting its backdrop.
    enum Motion {
        /// Selection changes, chips, toggles.
        static let snap = Animation.snappy(duration: 0.26, extraBounce: 0.02)
        /// Glass shapes merging or splitting.
        static let morph = Animation.smooth(duration: 0.38)
        /// Cards appearing after a load.
        static let reveal = Animation.smooth(duration: 0.3)
        /// The status pulse on a live dot.
        static let pulse = Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)
    }

    // MARK: - Depth

    /// Content-layer shadow. Deliberately soft and single-layer: iOS 26 draws its own shadow under
    /// glass, and a second one under the card underneath makes the stack look muddy.
    enum Shadow {
        static let color = Color.black.opacity(0.10)
        static let radius: CGFloat = 14
        static let y: CGFloat = 6
    }

    /// Hairline width. `1 / displayScale` would be crisper but reads as a hard line against glass,
    /// so the port uses a full point at low opacity instead.
    static let strokeWidth: CGFloat = 1
}

extension UIColor {
    /// `0xRRGGBB` → opaque colour, in the sRGB (device) space so the hex matches the design values.
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
