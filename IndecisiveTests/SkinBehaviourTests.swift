import XCTest
import SwiftUI
@testable import Indecisive

/// Per-skin decisions the snapshot tests can't see.
///
/// The snapshots pin each skin's resting frame, but they run under Reduce
/// Motion — which hides confetti entirely — and a still image can't show a
/// gesture. These pin the decisions that only show up in motion or in gesture
/// handling, so they can't drift unnoticed. The expected values are the ones the
/// code hard-coded before those decisions were made exhaustive per skin.
final class SkinBehaviourTests: XCTestCase {

    private func rgba(_ color: Color) -> [CGFloat] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    // MARK: Shake to pick

    func testOnlyTheEightBallPicksOnShake() {
        XCTAssertTrue(Skin.eightBall.shakeToPick, "\"ASK. SHAKE. OBEY.\" is the 8-Ball's own toy")
        XCTAssertFalse(Skin.prizeWheel.shakeToPick)
        XCTAssertFalse(Skin.gashapon.shakeToPick)
    }

    // MARK: Confetti

    func testEveryConfettiStyleHasColoursToCycleThrough() {
        // `Confetti.makePieces` indexes `colors[i % colors.count]`, so an empty
        // list would trap the moment a reveal appeared.
        for skin in Skin.all {
            XCTAssertFalse(Confetti.style(for: skin).colors.isEmpty, "\(skin.name) has no confetti colours")
        }
    }

    func testEightBallConfettiIsTightlyRoundedAndUnoutlined() {
        let palette = Skin.eightBall.palette
        let style = Confetti.style(for: .eightBall)
        XCTAssertEqual(style.colors.map(rgba), (palette.flavors + [palette.surface]).map(rgba))
        XCTAssertEqual(style.cornerRadius, 2)
        XCTAssertNil(style.outline)
    }

    func testWheelConfettiIsInkOutlined() {
        let palette = Skin.prizeWheel.palette
        let style = Confetti.style(for: .prizeWheel)
        XCTAssertEqual(style.colors.map(rgba), (palette.flavors + [palette.surface]).map(rgba))
        XCTAssertEqual(style.cornerRadius, 3)
        XCTAssertEqual(style.outline.map(rgba), rgba(palette.primaryText))
    }

    func testGashaponConfettiAvoidsItsCyanRevealBackground() {
        // Its cyan flavour would vanish against the cyan reveal screen, so it
        // uses the mockup's own yellow, cream, pink and mint instead.
        let flavors = Skin.gashapon.palette.flavors
        let style = Confetti.style(for: .gashapon)
        XCTAssertEqual(
            style.colors.map(rgba),
            [GashaponPaint.coin, GashaponPaint.shell, flavors[0], flavors[2]].map(rgba)
        )
        XCTAssertFalse(style.colors.map(rgba).contains(rgba(flavors[1])), "the cyan flavour must not be in the mix")
        XCTAssertEqual(style.cornerRadius, 3)
        XCTAssertNil(style.outline)
    }
}
