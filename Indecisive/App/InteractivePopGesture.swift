import SwiftUI
import UIKit

/// Restores the interactive edge-swipe-to-go-back gesture on a screen that
/// hides the system back button.
///
/// UIKit's default `interactivePopGestureRecognizer` delegate requires a
/// *visible* system back button to allow the gesture to begin. `ListDetailView`
/// hides it (`.navigationBarBackButtonHidden(true)`) so it can show its own
/// skin-styled "‹ Lists" button instead — which, as an unfortunate side
/// effect, silently disables swipe-to-go-back too, even though nothing
/// about a custom back button should prevent swiping back to the previous
/// screen. This becomes the gesture's own delegate to bypass that check,
/// gated only on the same "there's actually something to pop back to"
/// condition the system delegate already uses.
private final class PopGestureEnablerViewController: UIViewController, UIGestureRecognizerDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PopGestureEnablerViewController {
        PopGestureEnablerViewController()
    }

    func updateUIViewController(_ uiViewController: PopGestureEnablerViewController, context: Context) {}
}

extension View {
    /// Re-enables edge-swipe-to-go-back on this screen's navigation stack
    /// after `.navigationBarBackButtonHidden(true)` disabled it as a side
    /// effect of hiding the system back button. See
    /// `PopGestureEnablerViewController`.
    func restoresInteractivePopGesture() -> some View {
        background(InteractivePopGestureEnabler().frame(width: 0, height: 0))
    }
}
