import SwiftUI

/// The app's real root, once `AppRoot` has resolved the current skin from
/// `@AppStorage` and injected it into the environment.
///
/// `SkinComponentGallery` (Phase 2's visual-QA screen) is no longer shown
/// here but the file is kept around — it's still the fastest way to check
/// every skin's shared components side by side after a token or component
/// change, without needing to click through the real navigation.
struct RootView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    RootView()
}
