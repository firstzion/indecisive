import XCTest
import SwiftData
@testable import IndecisiveKit

/// Tests for the SwiftData-backed half of `PickService`: reading a real
/// `PickList`, writing `Pick` history, and the global counter.
final class PickServiceIntegrationTests: XCTestCase {

    func testPickReturnsAnItemFromTheList() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch Places")
        list.items = [PickItem(name: "Pho Palace", sortOrder: 0), PickItem(name: "Sushi Counter", sortOrder: 1)]
        context.insert(list)

        let service = PickService(context: context)
        let result = service.pick(from: list)

        XCTAssertNotNil(result)
        XCTAssertTrue(list.items.contains(where: { $0.name == result?.name }))
    }

    func testPickOnEmptyListReturnsNil() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Empty List")
        context.insert(list)

        let service = PickService(context: context)
        XCTAssertNil(service.pick(from: list))
    }

    func testRecordAcceptedUpdatesLastAcceptedPick() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch Places")
        let item = PickItem(name: "Pho Palace")
        list.items = [item]
        context.insert(list)

        let service = PickService(context: context)
        XCTAssertNil(list.lastAcceptedPick)

        service.record(item, in: list, accepted: true)

        XCTAssertEqual(list.lastAcceptedPick?.itemName, "Pho Palace")
        XCTAssertEqual(list.picks.count, 1)
    }

    func testRejectedPicksDoNotBecomeLastAcceptedPick() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch Places")
        let item = PickItem(name: "Pho Palace")
        list.items = [item]
        context.insert(list)

        let service = PickService(context: context)
        service.record(item, in: list, accepted: false)

        XCTAssertNil(list.lastAcceptedPick, "a rejected re-roll must not count as the last accepted pick")
        XCTAssertEqual(list.picks.count, 1, "but it still shows up in history")
    }

    func testLastAcceptedPickIsTheMostRecentOne() throws {
        let context = try TestSupport.makeInMemoryContext()
        let list = PickList(name: "Lunch Places")
        let itemA = PickItem(name: "Sushi Counter")
        let itemB = PickItem(name: "Pho Palace")
        list.items = [itemA, itemB]
        context.insert(list)

        let earlier = Pick(itemName: itemA.name, date: .now.addingTimeInterval(-3600), accepted: true)
        let later = Pick(itemName: itemB.name, date: .now, accepted: true)
        context.insert(earlier)
        context.insert(later)
        list.picks = [earlier, later]

        XCTAssertEqual(list.lastAcceptedPick?.itemName, itemB.name)
    }

    func testTotalPickCountSpansAllLists() throws {
        let context = try TestSupport.makeInMemoryContext()
        let lunch = PickList(name: "Lunch Places")
        let movies = PickList(name: "Movie Night")
        let lunchItem = PickItem(name: "Pho Palace")
        let movieItem = PickItem(name: "Some Movie")
        lunch.items = [lunchItem]
        movies.items = [movieItem]
        context.insert(lunch)
        context.insert(movies)

        let service = PickService(context: context)
        XCTAssertEqual(service.totalPickCount, 0)

        service.record(lunchItem, in: lunch, accepted: true)
        service.record(movieItem, in: movies, accepted: false)
        service.record(lunchItem, in: lunch, accepted: false) // a re-roll still counts

        XCTAssertEqual(service.totalPickCount, 3, "every pick counts, accepted or not")
    }
}
