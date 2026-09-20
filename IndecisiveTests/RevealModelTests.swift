import XCTest
import SwiftData
@testable import Indecisive

final class RevealModelTests: XCTestCase {

    func testInitFailsForAnEmptyList() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Empty")
        context.insert(list)

        XCTAssertNil(RevealModel(list: list, service: PickService(context: context)))
    }

    func testInitPicksAWinnerFromTheList() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch")
        list.items = [PickItem(name: "A"), PickItem(name: "B")]
        context.insert(list)

        let model = try XCTUnwrap(RevealModel(list: list, service: PickService(context: context)))
        XCTAssertTrue(list.items.contains { $0.name == model.winner.name })
    }

    func testAcceptRecordsAnAcceptedPick() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch")
        list.items = [PickItem(name: "A")]
        context.insert(list)

        let model = try XCTUnwrap(RevealModel(list: list, service: PickService(context: context)))
        model.accept()

        XCTAssertEqual(list.lastAcceptedPick?.itemName, "A")
    }

    func testAcceptingTwiceOnlyRecordsOnePick() throws {
        // "LOCK IT IN" dismisses the reveal, and dismissal isn't instant, so
        // a double-tap used to land twice — two accepted picks in the list's
        // history, and the running counter up by two, from one user action.
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch")
        list.items = [PickItem(name: "A")]
        context.insert(list)

        let service = PickService(context: context)
        let model = try XCTUnwrap(RevealModel(list: list, service: service))
        model.accept()
        model.accept()
        model.accept()

        XCTAssertEqual(list.picks.count, 1, "only the first accept should have been recorded")
        XCTAssertEqual(service.totalPickCount, 1, "and the running total should agree")
        XCTAssertTrue(model.hasAccepted)
    }

    func testRerollNeverRepeatsAnyPreviouslyRejectedWinnerBeforeFullExhaustion() throws {
        // PickService.choose (Phase 1) resets its exclusion pool once every
        // candidate has been rejected — so once *all* items in a session
        // have been rejected, re-offering one of them again is correct,
        // expected behavior, not a bug. What's actually guaranteed is that
        // no name repeats *before* the pool could possibly be exhausted.
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch")
        let names = ["A", "B", "C", "D", "E"]
        list.items = names.map { PickItem(name: $0) }
        context.insert(list)

        let model = try XCTUnwrap(RevealModel(list: list, service: PickService(context: context)))
        var seen: Set<String> = [model.winner.name]

        // With 5 items, none of the first 4 re-rolls can have exhausted the
        // pool (that needs all 5 rejected), so none should ever repeat a
        // name already seen this session.
        for _ in 0..<(names.count - 1) {
            model.reroll()
            XCTAssertFalse(seen.contains(model.winner.name), "repeated '\(model.winner.name)' before the pool could have been exhausted")
            seen.insert(model.winner.name)
        }
    }

    func testRerollOnASingleItemListStillProducesAWinner() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Solo")
        list.items = [PickItem(name: "Only")]
        context.insert(list)

        let model = try XCTUnwrap(RevealModel(list: list, service: PickService(context: context)))
        model.reroll() // exhausts the pool immediately -> resets -> "Only" again

        XCTAssertEqual(model.winner.name, "Only")
    }

    func testRerollTokenChangesEvenWhenTheWinnerStaysTheSame() throws {
        // RevealView keys its intro-animation replay and VoiceOver
        // announcement off `rerollToken`, not `winner.id` — a one-item
        // list re-rolls back onto the same `PickItem`, so `winner.id`
        // alone wouldn't change and the UI would silently do nothing.
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Solo")
        list.items = [PickItem(name: "Only")]
        context.insert(list)

        let model = try XCTUnwrap(RevealModel(list: list, service: PickService(context: context)))
        let tokenBefore = model.rerollToken
        model.reroll() // exhausts the pool immediately -> resets -> "Only" again

        XCTAssertEqual(model.winner.name, "Only", "sanity check: this reroll really did land on the same item")
        XCTAssertNotEqual(model.rerollToken, tokenBefore, "a same-winner reroll must still produce a fresh token")
    }

    func testEveryRerollIsRecordedAsARejection() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch")
        list.items = [PickItem(name: "A"), PickItem(name: "B")]
        context.insert(list)

        let model = try XCTUnwrap(RevealModel(list: list, service: PickService(context: context)))
        model.reroll()
        model.reroll()

        XCTAssertEqual(list.picks.count, 2)
        XCTAssertTrue(list.picks.allSatisfy { !$0.accepted })
    }
}
