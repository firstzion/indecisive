import SwiftUI

extension View {
    /// Idles this view with `motion`: the loop starts when it appears. Under
    /// Reduce Motion (or the tests' equivalent) it never starts and the view
    /// holds the resting pose `IdleMotion` documents for that case.
    func indIdle(_ motion: IdleMotion) -> some View {
        modifier(IdleMotionModifier(motion: motion))
            // A different motion (the skin was switched) starts afresh, from rest.
            .id(motion)
    }
}

private struct IdleMotionModifier: ViewModifier {
    let motion: IdleMotion

    @State private var running = false
    @Environment(\.indReducedMotion) private var reduceMotion

    // Each case applies only its own effect, so a view that doesn't idle — or
    // idles differently — carries no extra no-op modifiers.
    @ViewBuilder
    func body(content: Content) -> some View {
        switch motion {
        case .none:
            content
        case let .float(distance, _):
            content.offset(y: running ? -distance : 0).onAppear(perform: start)
        case .spin:
            content.rotationEffect(.degrees(running ? 360 : 0)).onAppear(perform: start)
        case let .pulse(low, _):
            content.opacity(running ? 1 : low).onAppear(perform: start)
        case let .wiggle(degrees, _):
            content.rotationEffect(.degrees(running ? degrees : -degrees)).onAppear(perform: start)
        }
    }

    private func start() {
        guard !reduceMotion, let animation else { return }
        withAnimation(animation) { running = true }
    }

    private var animation: Animation? {
        switch motion {
        case .none: return nil
        case let .float(_, halfPeriod): return .easeInOut(duration: halfPeriod).repeatForever(autoreverses: true)
        case let .spin(period): return .linear(duration: period).repeatForever(autoreverses: false)
        case let .pulse(_, halfPeriod): return .easeInOut(duration: halfPeriod).repeatForever(autoreverses: true)
        case let .wiggle(_, halfPeriod): return .easeInOut(duration: halfPeriod).repeatForever(autoreverses: true)
        }
    }
}
