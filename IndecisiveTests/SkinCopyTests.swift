import XCTest
@testable import Indecisive

final class SkinCopyTests: XCTestCase {

    func testSkinForIDReturnsTheMatchingSkin() {
        for id in SkinID.allCases {
            XCTAssertEqual(Skin.skin(for: id).id, id)
        }
    }

    func testAllListsEverySkinIDExactlyOnceInOrder() {
        // Every skin-coverage test iterates `Skin.all`, so a skin missing,
        // duplicated or reordered here is missing from all of them at once.
        XCTAssertEqual(Skin.all.map(\.id), SkinID.allCases)
    }

    func testCountLinePluralizes() {
        XCTAssertEqual(Skin.eightBall.copy.countLine(1), "1 item")
        XCTAssertEqual(Skin.eightBall.copy.countLine(2), "2 items")
        XCTAssertEqual(Skin.prizeWheel.copy.countLine(1), "1 wedge")
        XCTAssertEqual(Skin.prizeWheel.copy.countLine(2), "2 wedges")
        XCTAssertEqual(Skin.gashapon.copy.countLine(1), "1 capsule inside")
        XCTAssertEqual(Skin.gashapon.copy.countLine(14), "14 capsules inside")
        XCTAssertEqual(Skin.crystalBall.copy.countLine(1), "1 possible future")
        XCTAssertEqual(Skin.crystalBall.copy.countLine(14), "14 possible futures")
    }

    func testGashaponHomeSubtitlePluralizes() {
        let copy = Skin.gashapon.copy
        XCTAssertEqual(copy.homeSubtitle(1), "1 machine loaded · ¥0 per turn")
        XCTAssertEqual(copy.homeSubtitle(5), "5 machines loaded · ¥0 per turn")
    }

    func testGashaponRevealCopyNamesTheWinnerAndTheOdds() {
        let copy = Skin.gashapon.copy
        XCTAssertEqual(copy.revealWinnerLabel, "YOU GOT")
        XCTAssertEqual(copy.revealSupport(14), "1 of 14 · duplicate protection off")
        // Only Gashapon has a "you got" label; the other skins just show the name.
        XCTAssertNil(Skin.eightBall.copy.revealWinnerLabel)
        XCTAssertNil(Skin.prizeWheel.copy.revealWinnerLabel)
        XCTAssertNil(Skin.crystalBall.copy.revealWinnerLabel)
    }

    func testCrystalBallSpeaksInTheMockupsWords() {
        let copy = Skin.crystalBall.copy
        // Static, like the Wheel's: the mockup's subtitle and footer don't count anything.
        XCTAssertEqual(copy.homeSubtitle(0), "Madame Random will see you now")
        XCTAssertEqual(copy.homeSubtitle(99), "Madame Random will see you now")
        XCTAssertEqual(copy.homeFooter(412), "The mists are ready when you are")
        XCTAssertEqual(copy.newListRow, "Summon a new list")
        XCTAssertEqual(copy.detailHeadline(1), "1 future inside")
        XCTAssertEqual(copy.detailHeadline(14), "14 futures inside")
        XCTAssertEqual(copy.addRow, "Add to the prophecy")
        XCTAssertEqual(copy.ctaCaption, "Cross my palm and tap")
        XCTAssertEqual(copy.ctaLabel, "Pick For Me")
        XCTAssertEqual(copy.revealKicker, "THE MISTS HAVE PARTED")
        XCTAssertEqual(copy.acceptLabel, "So it is written")
        XCTAssertEqual(copy.rerollLabel, "Consult again")
    }

    func testCrystalBallRevealSupportCountsTheCandidatesAndBreaksWhereTheMockupDoes() {
        // The mockup breaks the line after "were".
        XCTAssertEqual(
            Skin.crystalBall.copy.revealSupport(14),
            "Chosen from 14. The spirits were\nunanimous, which never happens."
        )
        XCTAssertEqual(
            Skin.crystalBall.copy.revealSupport(1),
            "Chosen from 1. The spirits were\nunanimous, which never happens."
        )
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
        XCTAssertEqual(Skin.eightBall.copy.lastPickLine("Pho Palace", date), "Ball last said: Pho Palace")
        XCTAssertEqual(Skin.prizeWheel.copy.lastPickLine("Pho Palace", date), "Last spin landed on Pho Palace")
        XCTAssertTrue(Skin.gashapon.copy.lastPickLine("Pho Palace", date).hasPrefix("Last drop: Pho Palace,"))
        XCTAssertEqual(Skin.crystalBall.copy.lastPickLine("Pho Palace", date), "The mists last chose Pho Palace")
    }

    func testEveryEmptyStateCopyIsNonEmptyAndSkinFlavored() {
        // PLAN.md Phase 6: "Empty states per skin" — a regression test that
        // each skin has its own strings rather than one falling back to a
        // shared default that would defeat the point.
        let all = Skin.all
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
        let all = Skin.all
        for skin in all {
            XCTAssertFalse(skin.copy.homeEmptyStateTitle.isEmpty, "\(skin.name) has no home empty-state title")
            XCTAssertFalse(skin.copy.homeEmptyStateMessage.isEmpty, "\(skin.name) has no home empty-state message")
        }
        let titles = Set(all.map(\.copy.homeEmptyStateTitle))
        XCTAssertEqual(titles.count, all.count, "home empty-state titles should differ per skin, not share one default")
    }
}
