import SwiftUI
import UIKit

/// Bridges UIKit's shake-motion event (`motionEnded`) into SwiftUI. Used
/// only by the 8-Ball skin, which lets you shake the phone instead of
/// tapping the CTA or "SHAKE AGAIN" — matching its own copy ("ASK. SHAKE.
/// OBEY.").
///
/// SwiftUI has no shake gesture, and `motionEnded` only reaches whichever
/// object is first responder. Rather than subclassing `UIWindow` (which
/// needs a custom `UIApplicationDelegate` to install), this inserts a
/// zero-size `UIViewController` that becomes first responder on appear —
/// the standard, app-delegate-free way to catch a shake in a pure SwiftUI
/// `App` lifecycle.
private struct ShakeDetectingRepresentable: UIViewControllerRepresentable {
    let action: () -> Void
    /// Whether this screen's detector may (re-)claim first responder on
    /// this update. A screen that also hosts a `TextField` passes `false`
    /// while that field wants the keyboard — without this, reclaiming
    /// first responder here would resign the field on the very next
    /// SwiftUI update (e.g. the next keystroke), silently kicking the
    /// user out of whatever they were typing.
    var canClaimFocus: Bool = true

    func makeUIViewController(context: Context) -> ShakeDetectingViewController {
        let controller = ShakeDetectingViewController()
        controller.onShake = action
        return controller
    }

    func updateUIViewController(_ uiViewController: ShakeDetectingViewController, context: Context) {
        uiViewController.onShake = action
        // Reclaims first responder if another screen's own shake detector
        // took it and never gave it back — e.g. after `RevealView`'s
        // `fullScreenCover` (which installs its own detector on appear)
        // is dismissed. `viewDidAppear` alone doesn't cover that case: it
        // only fires on *this* controller's own appearance, never when a
        // sibling detector elsewhere resigns first responder.
        // `becomeFirstResponder()` is a cheap no-op when already first
        // responder, so calling it on every update (while `canClaimFocus`
        // holds) is safe.
        guard canClaimFocus, uiViewController.isViewLoaded, uiViewController.view.window != nil else { return }
        uiViewController.becomeFirstResponder()
    }
}

private final class ShakeDetectingViewController: UIViewController {
    var onShake: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}

extension View {
    /// Calls `action` whenever the device is physically shaken. Only
    /// meaningful on a real device — in the Simulator, trigger it via
    /// Device ▸ Shake Gesture (⌃⌘Z).
    ///
    /// Pass `canClaimFocus: false` while this screen also has a
    /// `TextField` that wants the keyboard — see
    /// `ShakeDetectingRepresentable.canClaimFocus`.
    func onShake(canClaimFocus: Bool = true, perform action: @escaping () -> Void) -> some View {
        background(ShakeDetectingRepresentable(action: action, canClaimFocus: canClaimFocus).frame(width: 0, height: 0))
    }
}
