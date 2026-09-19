import XCTest
@testable import Indecisive

final class SkinCopyTests: XCTestCase {

    func testSkinForIDReturnsTheMatchingSkin() {
        XCTAssertEqual(Skin.skin(for: .gumball).id, .gumball)
        XCTAssertEqual(Skin.skin(for: .eightBall).id, .eightBall)
        XCTAssertEqual(Skin.skin(for: .prizeWheel).id, .prizeWheel)
    }

    func testGumballCopyPluralizes() {
        let copy = Skin.gumball.copy
        XCTAssertEqual(copy.countLine(1), "1 thing")
        XCTAssertEqual(copy.countLine(2), "2 things")
        XCTAssertEqual(copy.homeSubtitle(1), "1 list · infinite indecision")
        XCTAssertEqual(copy.homeSubtitle(5), "5 lists · infinite indecision")
    }

    func testEightBallHomeFooterIncludesTotalPickCount() {
        let copy = Skin.eightBall.copy
        XCTAssertEqual(copy.homeFooter(412), "THE BALL HAS SPOKEN 412 TIMES")
        XCTAssertEqual(copy.homeFooter(1), "THE BALL HAS SPOKEN 1 TIME")
        XCTAssertEqual(copy.homeFooter(0), "THE BALL HAS SPOKEN 0 TIMES")
    }

    func testEightBallRevealSupportCountsOtherContenders() {
        let copy = Skin.eightBall.copy
        XCTAssertEqual(
            copy.revealSupport(14),
            "Beat 13 other contenders. Arguing with a ball is undignified."
        )
        XCTAssertEqual(
            copy.revealSupport(1),
            "Beat 0 other contenders. Arguing with a ball is undignified."
        )
    }

    func testWheelCopyIgnoresCountWhereDesignIsStatic() {
        let copy = Skin.prizeWheel.copy
        XCTAssertEqual(copy.homeSubtitle(99), "Step right up, pick a wheel")
        XCTAssertEqual(copy.revealSupport(3), "The wheel does not negotiate.")
    }

    func testLastPickLineDiffersInToneAcrossSkins() {
        let date = Date()
        XCTAssertTrue(Skin.gumball.copy.lastPickLine("Pho Palace", date).hasPrefix("Last pick: Pho Palace,"))
        XCTAssertEqual(Skin.eightBall.copy.lastPickLine("Pho Palace", date), "Ball last said: Pho Palace")
        XCTAssertEqual(Skin.prizeWheel.copy.lastPickLine("Pho Palace", date), "Last spin landed on Pho Palace")
    }

    func testEveryEmptyStateCopyIsNonEmptyAndSkinFlavored() {
        // PLAN.md Phase 6: "Empty states per skin" — a regression test that
        // each skin has its own strings rather than one falling back to a
        // shared default that would defeat the point.
        let all = [Skin.gumball, Skin.eightBall, Skin.prizeWheel]
        for skin in all {
            XCTAssertFalse(skin.copy.emptyStateTitle.isEmpty, "\(skin.name) has no empty-state title")
            XCTAssertFalse(skin.copy.emptyStateMessage.isEmpty, "\(skin.name) has no empty-state message")
        }
        let titles = Set(all.map(\.copy.emptyStateTitle))
        XCTAssertEqual(titles.count, all.count, "empty-state titles should differ per skin, not share one default")
    }

    func testEveryHomeEmptyStateCopyIsNonEmptyAndSkinFlavored() {
        // Home's own "no lists yet" state — same regression-test shape as
        // the list-detail one above.
        let all = [Skin.gumball, Skin.eightBall, Skin.prizeWheel]
        for skin in all {
            XCTAssertFalse(skin.copy.homeEmptyStateTitle.isEmpty, "\(skin.name) has no home empty-state title")
            XCTAssertFalse(skin.copy.homeEmptyStateMessage.isEmpty, "\(skin.name) has no home empty-state message")
        }
        let titles = Set(all.map(\.copy.homeEmptyStateTitle))
        XCTAssertEqual(titles.count, all.count, "home empty-state titles should differ per skin, not share one default")
    }
}
