import SwiftUI
import UIKit

/// One beat of a skin's haptic pattern: something to feel `at` seconds after
/// the reveal appears.
struct HapticBeat: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case impact(UIImpactFeedbackGenerator.FeedbackStyle, intensity: Double)
        /// One tick of a selection wheel.
        case selection
        /// The "you have your answer" tap.
        case success
    }

    let at: Double
    let kind: Kind

    /// `.selection` ticks that come ever further apart across `duration` — a
    /// wheel slowing down and crossing wedge boundaries. An approximation of the
    /// motion, not tied to the exact wedge count.
    static func decelerating(over duration: Double, firstInterval: Double = 0.06, slowingBy factor: Double = 1.18) -> [HapticBeat] {
        var beats: [HapticBeat] = []
        var elapsed = 0.0
        var interval = firstInterval
        while elapsed < duration {
            beats.append(HapticBeat(at: elapsed, kind: .selection))
            elapsed += interval
            interval *= factor
        }
        return beats
    }
}

/// A looping motion for something that idles on screen. `.none` holds still.
/// Applied with `indIdle(_:)`, which also holds the resting pose under Reduce
/// Motion — so what each case looks like *at rest* is part of the contract.
enum IdleMotion: Sendable, Hashable {
    case none
    /// Bobs up by `distance` points and back; each way takes `halfPeriod`
    /// seconds. Rests at its lowest point.
    case float(distance: CGFloat, halfPeriod: Double)
    /// Turns a full circle every `period` seconds, at a steady pace. Rests upright.
    case spin(period: Double)
    /// Fades between `low` and full opacity; each way takes `halfPeriod`
    /// seconds. Rests at `low`.
    case pulse(low: Double, halfPeriod: Double)
    /// Rocks `degrees` either side of upright; each swing takes `halfPeriod`
    /// seconds. Rests tilted back, at `-degrees`.
    case wiggle(degrees: Double, halfPeriod: Double)
}

/// The "toy moment" that plays when the reveal appears — each skin's own
/// choreography, with the numbers it runs on.
///
/// `RevealCentrepiece` plays the animation from these numbers and `RevealView`
/// announces the winner to VoiceOver after `winnerLegibleAfter`, which is
/// derived from the same numbers — so what's on screen and what's announced
/// can't drift apart (they used to be two hand-kept tables in two files, and
/// the 8-Ball's disagreed).
enum RevealIntro: Sendable, Equatable {
    /// The ball wobbles for `swings` round trips of `2 × swingDuration` each,
    /// then the answer fades in over `answerFadeIn`.
    case wobble(swings: Int, swingDuration: Double, answerFadeIn: Double)
    /// The wheel spins `turns` full turns plus the way round to the winning
    /// wedge over `duration`; the name card is on screen `cardIn` seconds after
    /// it lands.
    case spin(duration: Double, turns: Int, cardIn: Double)
    /// The capsule pops in and its lid springs off `lidDelay` seconds later,
    /// taking `lidSettle` to come to rest.
    case popAndOpen(lidDelay: Double, lidSettle: Double)

    /// Seconds after the reveal appears until the winner is on screen and legible:
    /// the moment VoiceOver announces it.
    var winnerLegibleAfter: Double {
        switch self {
        case let .wobble(swings, swingDuration, answerFadeIn):
            return Double(swings) * 2 * swingDuration + answerFadeIn
        case let .spin(duration, _, cardIn):
            return duration + cardIn
        case let .popAndOpen(lidDelay, lidSettle):
            return lidDelay + lidSettle
        }
    }
}

/// Every timing, motion and haptic that differs between skins. Values only —
/// the views that play them are `RevealCentrepiece`, `HapticPlayer` and
/// `indIdle(_:)`.
struct SkinMotion: Sendable {
    let revealIntro: RevealIntro
    /// Played alongside `revealIntro`, by offset from the moment the reveal
    /// appears. Under Reduce Motion only the `.success` beat is played, straight
    /// away.
    let revealHaptics: [HapticBeat]
    /// The badge on the list-detail header.
    let heroBadge: IdleMotion
    /// The glyph inside the Pick For Me button.
    let ctaGlyph: IdleMotion
    /// The glyph beside the re-roll button's label.
    let rerollGlyph: IdleMotion
    /// The decoration behind the reveal (the 8-Ball's glow, Gashapon's sunburst).
    let revealBackdrop: IdleMotion
}
