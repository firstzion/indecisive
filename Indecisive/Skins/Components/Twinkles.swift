import SwiftUI

/// The back-and-forth of a CSS keyframe loop that runs 0% → 50% → 100% with `ease-in-out`
/// between the keyframes — the mockup's `pfm-twinkle` and `pfm-mist`. It is 0 at the start of
/// each period, 1 halfway through and 0 again at the end.
///
/// A pure function of the clock, like `ConfettiMotion`, so a test can ask where anything is at
/// any moment without waiting for an animation. `phaseOffset` starts a loop part-way round, which
/// is how the mockup's `animation-delay`s are used here: to put things out of step with one
/// another, not to make them wait.
enum Swing {
    static func value(at elapsed: Double, period: Double, phaseOffset: Double = 0) -> Double {
        guard period > 0 else { return 0 }
        var phase = ((elapsed + phaseOffset) / period).truncatingRemainder(dividingBy: 1)
        if phase < 0 { phase += 1 }
        let half = phase < 0.5 ? phase * 2 : (1 - phase) * 2
        // Smoothstep: flat at both ends like CSS's `ease-in-out`, and within a few per cent of it.
        return half * half * (3 - 2 * half)
    }
}

/// One of Crystal Ball's stars: where it sits, how big it is and the rhythm it twinkles to.
struct Twinkle: Equatable {
    /// Where the star's top-left corner is, as fractions of the screen's width and height.
    let x: CGFloat
    let y: CGFloat
    /// Its diameter, in points, at full size.
    let size: CGFloat
    /// Seconds for one full twinkle: swell, then fade back.
    let duration: Double
    /// How far round its loop it starts, seconds.
    let phaseOffset: Double
}

/// The mockup's `pfm-twinkle` keyframes, as a function of time:
///
///     0%    scale .6   opacity .35
///     50%   scale 1    opacity 1
///     100%  scale .6   opacity .35
enum TwinkleMotion {
    static let scaleLow = 0.6
    static let opacityLow = 0.35

    struct Pose: Equatable {
        let scale: Double
        let opacity: Double
    }

    static func pose(of star: Twinkle, at elapsed: Double) -> Pose {
        let swing = Swing.value(at: elapsed, period: star.duration, phaseOffset: star.phaseOffset)
        return Pose(
            scale: scaleLow + (1 - scaleLow) * swing,
            opacity: opacityLow + (1 - opacityLow) * swing
        )
    }

    /// The reveal's six stars, in the mockup's own places, sizes and rhythms. Their colours are
    /// the skin's (`ConfettiStyle.colors`, star by star), so gold, cyan, pink, gold, pale, pink
    /// in the mockup's order.
    static let constellation: [Twinkle] = [
        Twinkle(x: 0.11, y: 0.18, size: 9, duration: 2.1, phaseOffset: 0),
        Twinkle(x: 0.83, y: 0.22, size: 7, duration: 2.6, phaseOffset: 0.7),
        Twinkle(x: 0.22, y: 0.66, size: 8, duration: 2.4, phaseOffset: 1.2),
        Twinkle(x: 0.74, y: 0.60, size: 10, duration: 3.0, phaseOffset: 0.3),
        Twinkle(x: 0.47, y: 0.13, size: 7, duration: 2.8, phaseOffset: 1.6),
        Twinkle(x: 0.08, y: 0.44, size: 7, duration: 2.2, phaseOffset: 2.0),
    ]
}

/// The stars at one instant: each placed and dimmed by `TwinkleMotion`. Takes the time as a
/// plain number, so a test can render any moment.
struct TwinkleField: View {
    let stars: [Twinkle]
    let colors: [Color]
    let size: CGSize
    let elapsed: Double

    var body: some View {
        ZStack {
            // `colors[i % colors.count]` would trap on an empty list.
            if !colors.isEmpty {
                ForEach(stars.indices, id: \.self) { index in
                    let star = stars[index]
                    let pose = TwinkleMotion.pose(of: star, at: elapsed)
                    Circle()
                        .fill(colors[index % colors.count])
                        .frame(width: star.size, height: star.size)
                        .scaleEffect(pose.scale)
                        .opacity(pose.opacity)
                        .position(
                            x: star.x * size.width + star.size / 2,
                            y: star.y * size.height + star.size / 2
                        )
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

/// Crystal Ball's celebration behind the reveal (`ConfettiStyle.Motion.twinkling`): a few stars
/// that swell and fade in turn. Under Reduce Motion they hold still at the first instant of their
/// loops — unlike falling confetti, a still starfield still reads as one, so it stays.
struct Twinkles: View {
    let style: SkinRevealStyle.ConfettiStyle

    @State private var start = Date()
    @Environment(\.indReducedMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                TwinkleField(
                    stars: TwinkleMotion.constellation,
                    colors: style.colors,
                    size: proxy.size,
                    elapsed: reduceMotion ? 0 : timeline.date.timeIntervalSince(start)
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
