import XCTest
import SwiftUI
@testable import Indecisive

/// Per-skin decisions the snapshot tests can't see.
///
/// The snapshots pin each skin's resting frame, but they run under Reduce
/// Motion — which hides confetti entirely — and a still image can't show a
/// gesture. These pin the decisions that only show up in motion or in gesture
/// handling, so they can't drift unnoticed. The expected values are the ones the
/// code hard-coded before those decisions became tokens, written out as literals
/// here so they check the tokens rather than repeat them.
final class SkinBehaviourTests: XCTestCase {

    private func rgba(_ color: Color) -> [CGFloat] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    // MARK: Shake to pick

    func testOnlyTheEightBallPicksOnShake() {
        XCTAssertTrue(Skin.eightBall.traits.shakeToPick, "\"ASK. SHAKE. OBEY.\" is the 8-Ball's own toy")
        XCTAssertFalse(Skin.prizeWheel.traits.shakeToPick)
        XCTAssertFalse(Skin.gashapon.traits.shakeToPick)
    }

    // MARK: Reveal screen

    func testRevealColorSchemeMatchesEachSkinsLoudBackground() {
        // Set with the reveal background, not derived from Home's scheme — even
        // though all three shipped skins happen to agree with it today.
        XCTAssertEqual(Skin.eightBall.reveal.colorScheme, .dark)
        XCTAssertEqual(Skin.prizeWheel.reveal.colorScheme, .light)
        XCTAssertEqual(Skin.gashapon.reveal.colorScheme, .light)
    }

    func testOnlyTheEightBallShowsItsWinnerWithoutANameCard() {
        // The 8-Ball's centrepiece carries the name in its diamond window; the
        // other two put it in a card that appears with, or after, the intro.
        XCTAssertNil(Skin.eightBall.reveal.nameCard)
        XCTAssertEqual(Skin.prizeWheel.reveal.nameCard?.appearance, .afterIntro, "the spin has to land first")
        XCTAssertEqual(Skin.gashapon.reveal.nameCard?.appearance, .withCentrepiece)
    }

    func testOnlyTheWheelSetsItsRevealButtonsSideBySide() {
        XCTAssertEqual(Skin.eightBall.reveal.actions.axis, .vertical)
        XCTAssertEqual(Skin.prizeWheel.reveal.actions.axis, .horizontal)
        XCTAssertEqual(Skin.gashapon.reveal.actions.axis, .vertical)
    }

    // MARK: Confetti

    func testEveryConfettiStyleHasColoursToCycleThrough() {
        // `Confetti.makePieces` indexes `colors[i % colors.count]`, so an empty
        // list would trap the moment a reveal appeared.
        for skin in Skin.all {
            XCTAssertFalse(skin.reveal.confetti.colors.isEmpty, "\(skin.name) has no confetti colours")
        }
    }

    func testEightBallConfettiIsTightlyRoundedAndUnoutlined() {
        let style = Skin.eightBall.reveal.confetti
        // Its three flavours, then the card surface.
        XCTAssertEqual(
            style.colors.map(rgba),
            [0xFF4FD8, 0x4DE1FF, 0xC8FF4D, 0x241B52].map { rgba(Color(hex: $0)) }
        )
        XCTAssertEqual(style.cornerRadius, 2)
        XCTAssertNil(style.outline)
    }

    func testWheelConfettiIsInkOutlined() {
        let style = Skin.prizeWheel.reveal.confetti
        // Its four flavours, then the card surface.
        XCTAssertEqual(
            style.colors.map(rgba),
            [0xF0503C, 0xFFC93C, 0x1F9E8E, 0xFBF3E4, 0xFFFFFF].map { rgba(Color(hex: $0)) }
        )
        XCTAssertEqual(style.cornerRadius, 3)
        XCTAssertEqual(style.outline.map(rgba), rgba(Color(hex: 0x17130F)))
    }

    func testGashaponConfettiAvoidsItsCyanRevealBackground() {
        // Its cyan flavour would vanish against the cyan reveal screen, so it
        // uses the mockup's own yellow, cream, pink and mint instead.
        let style = Skin.gashapon.reveal.confetti
        XCTAssertEqual(
            style.colors.map(rgba),
            [0xFFD23D, 0xFFF7E8, 0xFF5D8F, 0x4BE0B0].map { rgba(Color(hex: $0)) }
        )
        XCTAssertFalse(
            style.colors.map(rgba).contains(rgba(Color(hex: 0x21C7E8))),
            "the cyan flavour must not be in the mix"
        )
        XCTAssertEqual(style.cornerRadius, 3)
        XCTAssertNil(style.outline)
    }
}
