import SwiftUI

/// Reads the user's chosen skin from `@AppStorage` and injects it into the
/// environment for everything below it.
///
/// There used to be a `hasChosenSkin` flag here gating a first-launch
/// `SkinOnboardingView` ("Choose your toy"). It defaulted to `true` and
/// nothing in the app ever set it `false`, so that screen could not be
/// reached in a shipping build — 41 lines with no entry point and no test.
/// Both are gone; the Skins sheet on Home is how a skin gets chosen, and it
/// always was.
public struct AppRoot: View {
    @AppStorage(SkinID.storageKey) private var skinIDRaw: String = SkinID.defaultID.rawValue

    private var currentSkin: Skin {
        Skin.skin(for: SkinID.resolving(skinIDRaw))
    }

    public init() {}

    public var body: some View {
        RootView()
            .skin(currentSkin)
            .animation(.easeInOut, value: skinIDRaw)
    }
}
