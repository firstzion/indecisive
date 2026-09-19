import SwiftUI

/// Reads the user's chosen skin from `@AppStorage` and injects it into the
/// environment for everything below it. Gates on `hasChosenSkin`: a fresh
/// install starts "already chosen" (`SkinID.defaultID`, no onboarding
/// step), so the app opens straight into `RootView`; `SkinOnboardingView`
/// only ever runs if something explicitly sets `hasChosenSkin` back to
/// `false`. Skins remain fully changeable afterwards via the Home "Skins"
/// sheet either way.
///
/// `hasChosenSkin` is a separate flag rather than inferring "already
/// chosen" from `skinIDRaw` itself — `@AppStorage` can't distinguish "never
/// set" from "explicitly set to the same value as the default", so there's
/// no way to tell those apart from `skinIDRaw` alone.
struct AppRoot: View {
    @AppStorage(SkinID.storageKey) private var skinIDRaw: String = SkinID.defaultID.rawValue
    @AppStorage(SkinID.hasChosenStorageKey) private var hasChosenSkin: Bool = true

    private var currentSkin: Skin {
        Skin.skin(for: SkinID(rawValue: skinIDRaw) ?? .defaultID)
    }

    var body: some View {
        Group {
            if hasChosenSkin {
                RootView()
            } else {
                SkinOnboardingView(skinIDRaw: $skinIDRaw, hasChosenSkin: $hasChosenSkin)
            }
        }
        .skin(currentSkin)
        .animation(.easeInOut, value: skinIDRaw)
        .animation(.easeInOut, value: hasChosenSkin)
    }
}
