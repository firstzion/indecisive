import UIKit

/// Plays a skin's `HapticBeat`s. A generator is created the first time its
/// kind is needed and reused after, so a run of identical ticks (the 8-Ball's,
/// the Wheel's) shares one — as they did when each skin drove its own.
@MainActor
final class HapticPlayer {
    private var impacts: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var selection: UISelectionFeedbackGenerator?

    func play(_ kind: HapticBeat.Kind) {
        switch kind {
        case let .impact(style, intensity):
            let generator = impacts[style] ?? UIImpactFeedbackGenerator(style: style)
            impacts[style] = generator
            generator.impactOccurred(intensity: intensity)
        case .selection:
            let generator = selection ?? UISelectionFeedbackGenerator()
            selection = generator
            generator.selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
