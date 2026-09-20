import XCTest
import SwiftUI
@testable import IndecisiveKit

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
        XCTAssertFalse(Skin.crystalBall.traits.shakeToPick, "\"Cross my palm and tap\": Crystal Ball is tapped, not shaken")
    }

    // MARK: Home

    func testEveryHomeTitleIsThePrimaryTextExceptCrystalBallsGold() {
        // A role of its own, but every skin but one has used its primary text; the mockups
        // say so, and this is what would notice one of them drifting.
        for skin in Skin.all where skin.id != .crystalBall {
            XCTAssertEqual(rgba(skin.palette.titleText), rgba(skin.palette.primaryText), "\(skin.name)")
        }
        XCTAssertEqual(rgba(Skin.crystalBall.palette.titleText), rgba(Color(hex: 0xF3C969)), "the mockup sets it in gold")
        XCTAssertEqual(rgba(Skin.crystalBall.palette.titleText), rgba(Skin.crystalBall.palette.accent))
    }

    // MARK: Reveal screen

    func testRevealColorSchemeMatchesEachSkinsLoudBackground() {
        // Set with the reveal background, not derived from Home's scheme — even
        // though all shipped skins happen to agree with it today.
        XCTAssertEqual(Skin.eightBall.reveal.colorScheme, .dark)
        XCTAssertEqual(Skin.prizeWheel.reveal.colorScheme, .light)
        XCTAssertEqual(Skin.gashapon.reveal.colorScheme, .light)
        XCTAssertEqual(Skin.crystalBall.reveal.colorScheme, .dark)
    }

    func testOnlyTheEightBallAndCrystalBallShowTheirWinnerWithoutANameCard() {
        // The 8-Ball's centrepiece carries the name in its diamond window and Crystal Ball's in
        // the ball; the other two put it in a card that appears with, or after, the intro.
        XCTAssertNil(Skin.eightBall.reveal.nameCard)
        XCTAssertNil(Skin.crystalBall.reveal.nameCard)
        XCTAssertEqual(Skin.prizeWheel.reveal.nameCard?.appearance, .afterIntro, "the spin has to land first")
        XCTAssertEqual(Skin.gashapon.reveal.nameCard?.appearance, .withCentrepiece)
    }

    func testEverySkinSaysItsSupportLineExactlyOnce() {
        // A skin with a name card has the card draw the line inside itself; one with no card
        // sets it straight onto the background. Having both would say it twice, and having
        // neither would leave out a line every mockup has (the 8-Ball's went missing that way).
        for skin in Skin.all {
            let inCard = skin.reveal.nameCard != nil
            let loose = skin.reveal.supportLine != nil
            XCTAssertNotEqual(
                inCard, loose,
                inCard ? "\(skin.name) would say its support line twice" : "\(skin.name) never says its support line"
            )
        }
    }

    func testTheEightBallAndCrystalBallSetTheirSupportLineInTheirMockupsMutedViolets() {
        XCTAssertNil(Skin.prizeWheel.reveal.supportLine, "its card carries the line")
        XCTAssertNil(Skin.gashapon.reveal.supportLine, "its card carries the line")
        XCTAssertEqual(
            Skin.eightBall.reveal.supportLine.map { rgba($0.color) }, rgba(Color(hex: 0x9186C4)),
            "the 8-Ball mockup's #9186C4"
        )
        XCTAssertEqual(
            Skin.crystalBall.reveal.supportLine.map { rgba($0.color) }, rgba(Color(hex: 0xC0A7DC)),
            "the Crystal Ball mockup's #C0A7DC"
        )
    }

    func testOnlyTheWheelSetsItsRevealButtonsSideBySide() {
        XCTAssertEqual(Skin.eightBall.reveal.actions.axis, .vertical)
        XCTAssertEqual(Skin.prizeWheel.reveal.actions.axis, .horizontal)
        XCTAssertEqual(Skin.gashapon.reveal.actions.axis, .vertical)
        XCTAssertEqual(Skin.crystalBall.reveal.actions.axis, .vertical)
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

    func testOnlyCrystalBallCelebratesWithTwinklingStarsInsteadOfFallingConfetti() {
        for skin in Skin.all {
            XCTAssertEqual(
                skin.reveal.confetti.motion,
                skin.id == .crystalBall ? .twinkling : .falling,
                skin.name
            )
        }
    }

    func testCrystalBallsStarsAreTheMockupsColoursInTheMockupsOrder() {
        // Star by star: gold, cyan, pink, gold, pale, pink.
        let style = Skin.crystalBall.reveal.confetti
        XCTAssertEqual(
            style.colors.map(rgba),
            [0xF3C969, 0x8FE9FF, 0xFF8BD1, 0xF3C969, 0xF7EDFF, 0xFF8BD1].map { rgba(Color(hex: $0)) }
        )
        XCTAssertEqual(style.colors.count, TwinkleMotion.constellation.count, "one colour for each of the six stars")
        XCTAssertNil(style.outline)
    }

    // MARK: Crystal Ball's palette

    func testCrystalBallsListOrbsTakeTheirColoursFromOneTable() {
        // The palette's flavours are the orbs' bright centres, so the art and the palette can't
        // disagree about how many lists there are colours for.
        XCTAssertEqual(
            Skin.crystalBall.palette.flavors.map(rgba),
            CrystalPaint.tints.map { rgba($0.light) }
        )
        XCTAssertEqual(
            Skin.crystalBall.palette.flavors.map(rgba),
            [0xFF8BD1, 0x8FE9FF, 0xF3C969, 0xB7FFD8].map { rgba(Color(hex: $0)) },
            "pink, cyan, gold, mint, as on the mockup's Home"
        )
        XCTAssertEqual(rgba(CrystalPaint.tint(forFlavorIndex: 4).light), rgba(CrystalPaint.pink), "the fifth list is pink again")
        XCTAssertEqual(rgba(CrystalPaint.tint(forFlavorIndex: -1).light), rgba(CrystalPaint.mint), "and a negative index wraps, not traps")
    }

    func testCrystalBallsItemDotsRunGoldPinkCyan() {
        XCTAssertEqual(
            CrystalPaint.markers.map(rgba),
            [0xF3C969, 0xFF8BD1, 0x8FE9FF].map { rgba(Color(hex: $0)) }
        )
    }
}
