import XCTest
import SwiftData
@testable import IndecisiveKit

/// The app's CRUD. Until `ListEditor` existed none of this was reachable from
/// a unit test — it lived as private methods on `ListDetailView` — so adding,
/// renaming, reordering and deleting items had no coverage at all outside the
/// ~74 s UI suite.
@MainActor
final class ListEditorTests: XCTestCase {

    /// Held for the life of the test, not returned and discarded.
    ///
    /// This started out returning the container in a tuple the tests
    /// destructured with `_`, which released it immediately — while `list` and
    /// the editor's context were still using it. That crashed the whole bundle
    /// in a restart loop (17 restarts, 2 tests completing), which is the same
    /// failure mode REVIEW.md chased for two days under P1-5. A container
    /// outlives what it vends; hold onto it.
    private var container: ModelContainer!

    override func tearDown() async throws {
        container = nil
    }

    private func makeList(
        named name: String = "Lunch Places",
        items: [String] = []
    ) throws -> (editor: ListEditor, list: PickList) {
        container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let list = PickList(name: name, flavorIndex: 0, sortOrder: 0)
        list.items = items.enumerated().map { PickItem(name: $1, sortOrder: $0) }
        context.insert(list)
        return (ListEditor(context: context), list)
    }

    private func names(of list: PickList) -> [String] {
        list.orderedItems.map(\.name)
    }

    // MARK: Adding

    func testAddingAnItemPutsItLast() throws {
        let (editor, list) = try makeList(items: ["Taco Truck", "Sushi Counter"])
        editor.addItem(named: "Pho Palace", to: list)
        XCTAssertEqual(names(of: list), ["Taco Truck", "Sushi Counter", "Pho Palace"])
    }

    func testAddingTrimsSurroundingWhitespace() throws {
        let (editor, list) = try makeList()
        editor.addItem(named: "   Pho Palace \n", to: list)
        XCTAssertEqual(names(of: list), ["Pho Palace"])
    }

    func testAddingABlankNameDoesNothing() throws {
        let (editor, list) = try makeList(items: ["Taco Truck"])
        XCTAssertNil(editor.addItem(named: "   ", to: list))
        XCTAssertNil(editor.addItem(named: "", to: list))
        XCTAssertEqual(names(of: list), ["Taco Truck"], "a blank name must not add a row")
    }

    func testAddingAfterADeletionDoesNotReuseALiveSortOrder() throws {
        // `nextSortOrder` is max + 1, not count: deleting from the middle and
        // appending again must not collide with an order still in use.
        let (editor, list) = try makeList(items: ["A", "B", "C"])
        editor.delete(list.orderedItems[1], from: list)
        editor.addItem(named: "D", to: list)
        XCTAssertEqual(names(of: list), ["A", "C", "D"])
        XCTAssertEqual(list.orderedItems.map(\.sortOrder), [0, 1, 2], "orders should stay consecutive")
    }

    // MARK: Deleting

    func testDeletingRemovesTheItemAndClosesTheGap() throws {
        let (editor, list) = try makeList(items: ["A", "B", "C"])
        editor.delete(list.orderedItems[0], from: list)
        XCTAssertEqual(names(of: list), ["B", "C"])
        XCTAssertEqual(list.orderedItems.map(\.sortOrder), [0, 1])
    }

    func testDeletingTheLastItemLeavesAnEmptyList() throws {
        let (editor, list) = try makeList(items: ["Only"])
        editor.delete(list.orderedItems[0], from: list)
        XCTAssertTrue(list.items.isEmpty)
    }

    // MARK: Reordering

    func testMovingAnItemDownSwapsItWithTheNextOne() throws {
        let (editor, list) = try makeList(items: ["A", "B", "C"])
        editor.move(list.orderedItems[0], in: list, by: 1)
        XCTAssertEqual(names(of: list), ["B", "A", "C"])
    }

    func testMovingAnItemUpSwapsItWithThePreviousOne() throws {
        let (editor, list) = try makeList(items: ["A", "B", "C"])
        editor.move(list.orderedItems[2], in: list, by: -1)
        XCTAssertEqual(names(of: list), ["A", "C", "B"])
    }

    func testMovingTheFirstItemUpDoesNothing() throws {
        let (editor, list) = try makeList(items: ["A", "B"])
        editor.move(list.orderedItems[0], in: list, by: -1)
        XCTAssertEqual(names(of: list), ["A", "B"], "a move off the top must be a no-op, not a crash or a scramble")
    }

    func testMovingTheLastItemDownDoesNothing() throws {
        let (editor, list) = try makeList(items: ["A", "B"])
        editor.move(list.orderedItems[1], in: list, by: 1)
        XCTAssertEqual(names(of: list), ["A", "B"])
    }

    func testMovingAnItemThatIsNotInTheListDoesNothing() throws {
        let (editor, list) = try makeList(items: ["A", "B"])
        editor.move(PickItem(name: "Stranger", sortOrder: 0), in: list, by: 1)
        XCTAssertEqual(names(of: list), ["A", "B"])
    }

    func testAMoveAndItsInverseLeaveTheListAsItWas() throws {
        let (editor, list) = try makeList(items: ["A", "B", "C", "D"])
        editor.move(list.orderedItems[1], in: list, by: 1)
        editor.move(list.orderedItems[2], in: list, by: -1)
        XCTAssertEqual(names(of: list), ["A", "B", "C", "D"])
    }

    // MARK: Renumbering

    func testRenumberingRemovesGapsAndTies() throws {
        // Ties are the dangerous one: `orderedItems` sorts on `sortOrder` and
        // Swift's sort isn't stable, so two items sharing one could swap
        // places between redraws.
        let (editor, list) = try makeList()
        list.items = [
            PickItem(name: "A", sortOrder: 7),
            PickItem(name: "B", sortOrder: 7),
            PickItem(name: "C", sortOrder: 99),
        ]
        editor.renumber(list)
        XCTAssertEqual(Set(list.items.map(\.sortOrder)), [0, 1, 2], "every item should end up with its own position")
    }

    // MARK: Committing edits

    func testCommittingTrimsTheListNameAndEveryItemName() throws {
        let (editor, list) = try makeList(named: "  Lunch Places  ", items: ["  Taco Truck ", "Sushi Counter  "])
        editor.commitEdits(to: list, fallingBackTo: "Previous")
        XCTAssertEqual(list.name, "Lunch Places")
        XCTAssertEqual(names(of: list), ["Taco Truck", "Sushi Counter"])
    }

    func testCommittingAnEmptyListNameFallsBackToWhatItWasBefore() throws {
        // Clearing the title to retype it has to be allowed while typing, so
        // the recovery happens here, when editing ends.
        let (editor, list) = try makeList(named: "   ")
        editor.commitEdits(to: list, fallingBackTo: "Lunch Places")
        XCTAssertEqual(list.name, "Lunch Places")
    }

    func testCommittingAnEmptyItemNameGivesItAPlaceholder() throws {
        let (editor, list) = try makeList(items: ["Taco Truck", "   "])
        editor.commitEdits(to: list, fallingBackTo: "Previous")
        XCTAssertEqual(names(of: list), ["Taco Truck", ListEditor.untitledItemName])
    }

    func testCommittingLeavesAnAlreadyTidyListCompletelyAlone() throws {
        let (editor, list) = try makeList(named: "Lunch Places", items: ["Taco Truck"])
        editor.commitEdits(to: list, fallingBackTo: "Previous")
        XCTAssertEqual(list.name, "Lunch Places")
        XCTAssertEqual(names(of: list), ["Taco Truck"])
    }

    // MARK: Deleting a list

    func testDeletingAListRemovesItAndItsItems() throws {
        container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let editor = ListEditor(context: context)
        let list = PickList(name: "Lunch Places", flavorIndex: 0, sortOrder: 0)
        list.items = [PickItem(name: "Pho Palace", sortOrder: 0)]
        context.insert(list)
        try context.save()

        editor.delete(list)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PickList>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PickItem>()), 0, "the cascade rule should take the items with it")
    }

    // MARK: Pure

    func testNextSortOrderContinuesFromTheHighestInUse() {
        XCTAssertEqual(ListEditor.nextSortOrder(after: []), 0)
        XCTAssertEqual(ListEditor.nextSortOrder(after: [0, 1, 2]), 3)
        XCTAssertEqual(ListEditor.nextSortOrder(after: [5, 1, 3]), 6, "position, not count")
    }
}
