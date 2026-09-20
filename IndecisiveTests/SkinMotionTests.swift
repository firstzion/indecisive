import XCTest
import SwiftUI
@testable import Indecisive

/// The reveal's timings, haptics and idle motions — what the snapshot tests
/// can't see: they run under Reduce Motion, where every one of these collapses
/// to a resting pose. The expected values are the literals `RevealCentrepiece`,
/// `RevealView`, `HeroBadge` and friends hard-coded before they became tokens,
/// written out here again so the tests check the tokens rather than repeat them.
final class SkinMotionTests: XCTestCase {

    // MARK: VoiceOver's announcement follows the animation (REVIEW.md P1-2)

    func testAnnouncementIsImmediateUnderReduceMotion() {
        for skin in Skin.all {
            XCTAssertEqual(RevealView.announcementDelay(for: skin, reduceMotion: true), 0, "\(skin.name)")
        }
    }

    func testAnnouncementWaitsForTheSkinsOwnIntroToFinish() {
        for skin in Skin.all {
            let delay = RevealView.announcementDelay(for: skin, reduceMotion: false)
            XCTAssertEqual(delay, skin.motion.revealIntro.winnerLegibleAfter, accuracy: 1e-9, "\(skin.name)")
            XCTAssertGreaterThan(delay, 0, "\(skin.name) would announce before its intro has even started")
        }
    }

    /// The defect P1-2 found: the 8-Ball announced its winner at 1.0s, 80ms before
    /// the answer began to fade in. With the announcement derived from the intro's
    /// own numbers no skin can do that — and a new intro case has to say when its
    /// winner appears (this switch is exhaustive).
    func testNoSkinAnnouncesBeforeItsWinnerBeginsToAppear() {
        func appearsAt(_ intro: RevealIntro) -> Double {
            switch intro {
            case let .wobble(swings, swingDuration, _): return Double(swings) * 2 * swingDuration
            case let .spin(duration, _, _): return duration
            case let .popAndOpen(lidDelay, _): return lidDelay
            case let .mistParts(partDelay, _): return partDelay
            }
        }
        for skin in Skin.all {
            let intro = skin.motion.revealIntro
            let delay = RevealView.announcementDelay(for: skin, reduceMotion: false)
            XCTAssertGreaterThanOrEqual(delay, appearsAt(intro), "\(skin.name) announces its winner before it appears")
        }
    }

    func testEightBallAnnouncesOnlyOnceItsAnswerHasFadedIn() {
        // The wobble ends at 6 × 2 × 0.09 = 1.08s; the answer then fades in over 0.35s.
        XCTAssertEqual(RevealView.announcementDelay(for: .eightBall, reduceMotion: false), 1.43, accuracy: 1e-9)
    }

    func testWheelAndGashaponKeepTheirOriginalAnnouncementTimes() {
        XCTAssertEqual(RevealView.announcementDelay(for: .prizeWheel, reduceMotion: false), 2.9, accuracy: 1e-9)
        XCTAssertEqual(RevealView.announcementDelay(for: .gashapon, reduceMotion: false), 0.85, accuracy: 1e-9)
    }

    func testCrystalBallAnnouncesOnceTheMistHasPartedAndTheNameHasFadedIn() {
        // The mist parts at 0.5s and the name fades in over the next 0.5s.
        XCTAssertEqual(RevealView.announcementDelay(for: .crystalBall, reduceMotion: false), 1.0, accuracy: 1e-9)
    }

    // MARK: The intro's numbers

    func testIntroNumbersMatchWhatTheAnimationsHardCoded() {
        XCTAssertEqual(Skin.eightBall.motion.revealIntro, .wobble(swings: 6, swingDuration: 0.09, answerFadeIn: 0.35))
        XCTAssertEqual(Skin.prizeWheel.motion.revealIntro, .spin(duration: 2.8, turns: 4, cardIn: 0.1))
        XCTAssertEqual(Skin.gashapon.motion.revealIntro, .popAndOpen(lidDelay: 0.25, lidSettle: 0.6))
        XCTAssertEqual(Skin.crystalBall.motion.revealIntro, .mistParts(partDelay: 0.5, nameFadeIn: 0.5))
    }

    // MARK: Haptics

    private func assertBeats(_ actual: [HapticBeat], _ expected: [HapticBeat], _ name: String, line: UInt = #line) {
        XCTAssertEqual(actual.count, expected.count, "\(name): number of beats", line: line)
        for (index, (a, e)) in zip(actual, expected).enumerated() {
            XCTAssertEqual(a.kind, e.kind, "\(name): beat \(index)", line: line)
            XCTAssertEqual(a.at, e.at, accuracy: 1e-9, "\(name): beat \(index) time", line: line)
        }
    }

    func testEveryHapticPatternEndsWithExactlyOneSuccessTap() {
        for skin in Skin.all {
            let beats = skin.motion.revealHaptics
            let successes = beats.filter { $0.kind == .success }
            XCTAssertEqual(successes.count, 1, "\(skin.name) should have exactly one success tap")
            XCTAssertEqual(beats.map(\.at).max(), successes.first?.at, "\(skin.name): the success tap should come last")
            XCTAssertTrue(beats.allSatisfy { $0.at >= 0 }, "\(skin.name) has a beat before the reveal appears")
        }
    }

    func testEightBallHapticsAreARigidTapThenTicksThenSuccess() {
        var expected: [HapticBeat] = [HapticBeat(at: 0, kind: .impact(.rigid, intensity: 1))]
        for tick in 1..<6 {
            expected.append(HapticBeat(at: Double(tick) * 0.09, kind: .impact(.rigid, intensity: 0.6)))
        }
        expected.append(HapticBeat(at: 0.09 * 2 * 6, kind: .success))
        assertBeats(Skin.eightBall.motion.revealHaptics, expected, "8-Ball")
    }

    func testWheelHapticsAreDeceleratingTicksThenSuccess() {
        // The old `playWheelTickHaptics(duration: 2.8)`, written out again.
        var expected: [HapticBeat] = []
        var elapsed = 0.0
        var interval = 0.06
        while elapsed < 2.8 {
            expected.append(HapticBeat(at: elapsed, kind: .selection))
            elapsed += interval
            interval *= 1.18
        }
        expected.append(HapticBeat(at: 2.8, kind: .success))
        assertBeats(Skin.prizeWheel.motion.revealHaptics, expected, "Wheel")
    }

    func testGashaponHapticsAreTwoCrankTicksALidBumpThenSuccess() {
        assertBeats(
            Skin.gashapon.motion.revealHaptics,
            [
                HapticBeat(at: 0, kind: .impact(.rigid, intensity: 1)),
                HapticBeat(at: 0.1, kind: .impact(.rigid, intensity: 0.7)),
                HapticBeat(at: 0.25, kind: .impact(.medium, intensity: 1)),
                HapticBeat(at: 0.6, kind: .success),
            ],
            "Gashapon"
        )
    }

    func testCrystalBallHapticsAreAShimmerALightTapAsTheMistPartsThenSuccess() {
        assertBeats(
            Skin.crystalBall.motion.revealHaptics,
            [
                HapticBeat(at: 0, kind: .impact(.soft, intensity: 0.9)),
                HapticBeat(at: 0.16, kind: .impact(.soft, intensity: 0.5)),
                HapticBeat(at: 0.32, kind: .impact(.soft, intensity: 0.7)),
                HapticBeat(at: 0.5, kind: .impact(.light, intensity: 1)),
                HapticBeat(at: 1.0, kind: .success),
            ],
            "Crystal Ball"
        )
    }

    func testDeceleratingTicksSlowDownAndStayInsideTheDuration() {
        let ticks = HapticBeat.decelerating(over: 2.8)
        XCTAssertGreaterThan(ticks.count, 5)
        XCTAssertTrue(ticks.allSatisfy { $0.kind == .selection && $0.at < 2.8 })
        let gaps = zip(ticks, ticks.dropFirst()).map { $1.at - $0.at }
        XCTAssertEqual(gaps, gaps.sorted(), "each gap should be longer than the last")
    }

    // MARK: Idle motion

    func testIdleMotionsMatchWhatEachComponentHardCoded() {
        let eightBall = Skin.eightBall.motion
        XCTAssertEqual(eightBall.heroBadge, .float(distance: 6, halfPeriod: 1.8))
        XCTAssertEqual(eightBall.ctaGlyph, IdleMotion.none)
        XCTAssertEqual(eightBall.rerollGlyph, .wiggle(degrees: 4, halfPeriod: 0.6))
        XCTAssertEqual(eightBall.revealBackdrop, .pulse(low: 0.45, halfPeriod: 1.3))

        let wheel = Skin.prizeWheel.motion
        XCTAssertEqual(wheel.heroBadge, .spin(period: 9))
        XCTAssertEqual(wheel.ctaGlyph, .spin(period: 2.4))
        XCTAssertEqual(wheel.rerollGlyph, IdleMotion.none)
        XCTAssertEqual(wheel.revealBackdrop, IdleMotion.none)

        let gashapon = Skin.gashapon.motion
        XCTAssertEqual(gashapon.heroBadge, .float(distance: 10, halfPeriod: 1.7))
        XCTAssertEqual(gashapon.ctaGlyph, .spin(period: 3))
        XCTAssertEqual(gashapon.rerollGlyph, .wiggle(degrees: 4, halfPeriod: 0.6))
        XCTAssertEqual(gashapon.revealBackdrop, .spin(period: 26))

        // The mockup's `pfm-float` (3.6s, and 2.6s), `pfm-twinkle` (1.6s) and `pfm-glow` (3s).
        let crystalBall = Skin.crystalBall.motion
        XCTAssertEqual(crystalBall.heroBadge, .float(distance: 10, halfPeriod: 1.8))
        XCTAssertEqual(crystalBall.ctaGlyph, .float(distance: 10, halfPeriod: 1.3))
        XCTAssertEqual(crystalBall.rerollGlyph, .twinkle(scaleLow: 0.6, opacityLow: 0.35, halfPeriod: 0.8))
        XCTAssertEqual(crystalBall.revealBackdrop, .pulse(low: 0.45, halfPeriod: 1.5))
    }
}
