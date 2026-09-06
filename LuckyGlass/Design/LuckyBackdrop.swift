import SwiftUI

/// The ambient wash every screen sits on.
///
/// Liquid Glass refracts and reflects whatever is behind it, so a flat page colour makes the chrome
/// look like frosted plastic. Two wide radial blooms give the glass something to bend without
/// adding contrast that would fight the text on top of it — the original's plain grey page
/// background is deliberately not carried over.
struct LuckyBackdrop: View {
    /// The login screen lets the blooms drift; inside the app they stay put so a long scroll does
    /// not pay for an offscreen animation.
    var animated: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let span = max(size.width, size.height)
            ZStack {
                LinearGradient(
                    colors: [LuckyTheme.canvasTop, LuckyTheme.canvasBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                bloom(LuckyTheme.bloomTeal, radius: span * 0.72)
                    .frame(width: span * 1.44, height: span * 1.44)
                    .position(x: size.width * 0.12, y: size.height * 0.06 + phase)
                bloom(LuckyTheme.bloomViolet, radius: span * 0.66)
                    .frame(width: span * 1.32, height: span * 1.32)
                    .position(x: size.width * 0.96, y: size.height * 0.34 - phase)
                bloom(LuckyTheme.bloomTeal, radius: span * 0.5)
                    .frame(width: span, height: span)
                    .position(x: size.width * 0.68, y: size.height * 1.02 + phase * 0.5)
            }
            .compositingGroup()
        }
        .ignoresSafeArea()
        .onAppear(perform: start)
    }

    /// A single bloom. `RadialGradient` is already smooth, so no `blur` is involved — a blurred
    /// layer this large would cost a full-screen offscreen pass on every frame of a scroll.
    ///
    /// The blend differs by appearance: additive light on a near-black canvas reads as a glow, but
    /// on a white canvas it clips to white, so light mode composites normally at a lower alpha.
    private func bloom(_ colour: Color, radius: CGFloat) -> some View {
        let strong = scheme == .dark ? 0.34 : 0.20
        let mid = scheme == .dark ? 0.10 : 0.06
        return RadialGradient(
            colors: [colour.opacity(strong), colour.opacity(mid), colour.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
        .blendMode(scheme == .dark ? .plusLighter : .normal)
    }

    /// A 16-second there-and-back drift. Gated on both the caller's intent and Reduce Motion, and
    /// it only ever moves the blooms — the text layer above must never appear to breathe.
    private func start() {
        guard animated, !reduceMotion, phase == 0 else { return }
        withAnimation(.easeInOut(duration: 16).repeatForever(autoreverses: true)) {
            phase = 26
        }
    }
}
