import SwiftUI

private struct SkinEnvironmentKey: EnvironmentKey {
    static let defaultValue = Skin.gumball
}

extension EnvironmentValues {
    var skin: Skin {
        get { self[SkinEnvironmentKey.self] }
        set { self[SkinEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// Injects a skin for this view and everything below it.
    func skin(_ skin: Skin) -> some View {
        environment(\.skin, skin)
    }
}

private struct DisableIdleAnimationsKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Test-only escape hatch: forces every idle/intro animation in the
    /// Skins components to their resting pose, same as Reduce Motion, but
    /// settable from a test. `\.accessibilityReduceMotion` itself is a
    /// read-only bridge to the real system setting in recent SDKs — it
    /// can't be overridden via a plain `.environment()` call — so snapshot
    /// tests need their own key to get deterministic, un-animated frames.
    /// Every component that checks `accessibilityReduceMotion` checks this
    /// alongside it; app code never sets it.
    var indDisableIdleAnimationsForTesting: Bool {
        get { self[DisableIdleAnimationsKey.self] }
        set { self[DisableIdleAnimationsKey.self] = newValue }
    }

    /// What every animated Skins component actually reads: the real
    /// system Reduce Motion setting, OR'd with the test-only override
    /// above. One property to check instead of two.
    var indReducedMotion: Bool {
        accessibilityReduceMotion || indDisableIdleAnimationsForTesting
    }
}
