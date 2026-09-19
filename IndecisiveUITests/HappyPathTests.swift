import XCTest

/// PLAN.md Phase 7's end-to-end happy path: create a list, add 3 items,
/// pick, re-roll, accept, check the "last pick" line, switch skin, and
/// confirm the state survives the switch.
///
/// Launches with `-UITesting` (see `IndecisiveApp`), which forces an
/// in-memory store seeded fresh every run and skips onboarding — so this
/// test never touches, or depends on, real persisted simulator data.
///
/// The one exception is the skin *choice*, which lives in `UserDefaults`
/// rather than the store: the happy path really does switch it, so it starts
/// by picking the Wheel and ends by putting the Wheel back (see
/// `launchApp(pinningSkin:)` for why it can't just pin the skin instead).
final class HappyPathTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Launches the app on `-UITesting`'s fresh in-memory store, with
    /// onboarding already complete (`-hasChosenSkin YES`).
    ///
    /// `pinningSkin` also passes `-skin prizeWheel`, so the run starts on the
    /// same skin whatever the simulator last had selected. Both flags land in
    /// `UserDefaults`' argument domain (see `IndecisiveApp.isUITesting`),
    /// which outranks anything the app writes for the lifetime of the
    /// process — that's what keeps them off the simulator's real persisted
    /// defaults, but it also means the skin *can't be changed from the UI*
    /// while it's pinned. A test that switches skins therefore must not pin.
    private func launchApp(pinningSkin: Bool) {
        var arguments = ["-UITesting", "-hasChosenSkin", "YES"]
        if pinningSkin {
            arguments += ["-skin", "prizeWheel"]
        }
        app.launchArguments = arguments
        app.launch()
    }

    /// Opens the Skins sheet from Home and picks the tile for `id` (a
    /// `SkinID` raw value), which dismisses the sheet on its own.
    private func selectSkin(_ id: String) {
        app.buttons["Skins"].tap()
        let tile = app.buttons["skinTile-\(id)"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()
    }

    func testCreateListAddItemsPickRerollAcceptThenSwitchSkinAndStatePersists() throws {
        // Not pinned: this test switches skins, and a pinned `-skin` would
        // shadow the switch (the app would stay on the Wheel and the 8-Ball
        // check at the end could never pass). Pick the Wheel through the UI
        // instead, so the switch below is a real change whatever skin the
        // simulator happened to have persisted.
        launchApp(pinningSkin: false)
        selectSkin("prizeWheel")

        let itemNames = ["Hiking Trail", "Beach Day", "City Tour"]

        // MARK: Create a new list

        app.buttons["New list"].tap()
        let nameField = app.textFields["newListNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Weekend Trip")
        app.buttons["Create"].tap()

        let listRow = app.buttons["listRow-Weekend Trip"]
        XCTAssertTrue(listRow.waitForExistence(timeout: 5), "the new list should appear on Home")
        listRow.tap()

        // MARK: Add 3 items

        app.buttons["startAddItemButton"].tap()
        let itemField = app.textFields["newItemNameField"]
        XCTAssertTrue(itemField.waitForExistence(timeout: 5))
        for name in itemNames {
            XCTAssertTrue(itemField.waitForExistence(timeout: 5))
            itemField.tap()
            itemField.typeText(name)
            app.buttons["addItemButton"].tap()
        }

        // MARK: Pick, re-roll, accept

        let pickButton = app.buttons["pickForMeButton"]
        XCTAssertTrue(pickButton.waitForExistence(timeout: 5))
        XCTAssertTrue(pickButton.isEnabled, "the CTA must be enabled once the list has items")
        pickButton.tap()

        let rerollButton = app.buttons["rerollButton"]
        XCTAssertTrue(rerollButton.waitForExistence(timeout: 5), "the reveal should appear after tapping Pick For Me")
        rerollButton.tap()

        let acceptButton = app.buttons["acceptButton"]
        XCTAssertTrue(acceptButton.waitForExistence(timeout: 5))
        acceptButton.tap()

        // MARK: Check the "last pick" line

        let lastPickLine = app.staticTexts["lastPickLine"]
        XCTAssertTrue(lastPickLine.waitForExistence(timeout: 5), "accepting should dismiss the reveal and show the last pick")
        let acceptedName = try XCTUnwrap(
            itemNames.first { lastPickLine.label.contains($0) },
            "expected the last-pick line ('\(lastPickLine.label)') to name one of the 3 items just added"
        )

        // MARK: Switch skin

        app.buttons["backToListsButton"].tap()
        selectSkin("eightBall")

        // MARK: State persists across the switch

        let listRowAfterSwitch = app.buttons["listRow-Weekend Trip"]
        XCTAssertTrue(listRowAfterSwitch.waitForExistence(timeout: 5), "the list must still be there after switching skins")
        listRowAfterSwitch.tap()

        let lastPickLineAfterSwitch = app.staticTexts["lastPickLine"]
        XCTAssertTrue(lastPickLineAfterSwitch.waitForExistence(timeout: 5))
        XCTAssertTrue(
            lastPickLineAfterSwitch.label.contains(acceptedName),
            "the accepted pick ('\(acceptedName)') should survive the skin switch — got '\(lastPickLineAfterSwitch.label)'"
        )
        // Re-skinned in the 8-Ball's own voice, not the Wheel copy from
        // before the switch.
        XCTAssertTrue(lastPickLineAfterSwitch.label.hasPrefix("Ball last said:"))

        // MARK: Put the skin back

        // The switch was real, so it was written to the simulator's
        // persisted defaults — put the Wheel (the app's default skin) back
        // rather than leaving every later manual launch on the 8-Ball.
        app.buttons["backToListsButton"].tap()
        selectSkin("prizeWheel")
        XCTAssertTrue(
            app.buttons["listRow-Weekend Trip"].waitForExistence(timeout: 5),
            "the sheet should dismiss back to Home"
        )
    }

    /// The Home-screen swipe-to-delete: pulling a row far enough left asks
    /// for confirmation before actually removing it — dismissing the
    /// confirmation should leave the list untouched, only confirming
    /// should remove it.
    func testSwipeToDeleteListAsksForConfirmationFirst() throws {
        // Never touches the skin, so it can pin one for a uniform start.
        launchApp(pinningSkin: true)

        app.buttons["New list"].tap()
        let nameField = app.textFields["newListNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Delete Me")
        app.buttons["Create"].tap()

        let listRow = app.buttons["listRow-Delete Me"]
        XCTAssertTrue(listRow.waitForExistence(timeout: 5), "the new list should appear on Home")

        // MARK: Swiping and backing out leaves the list alone

        listRow.swipeLeft()
        let confirmAlert = app.alerts["Delete list?"]
        XCTAssertTrue(confirmAlert.waitForExistence(timeout: 5), "pulling far enough should ask for confirmation, not delete outright")
        confirmAlert.buttons["Cancel"].tap()
        XCTAssertTrue(listRow.waitForExistence(timeout: 5), "cancelling the confirmation must not delete the list")

        // MARK: Swiping and confirming actually deletes it

        listRow.swipeLeft()
        let secondConfirmAlert = app.alerts["Delete list?"]
        XCTAssertTrue(secondConfirmAlert.waitForExistence(timeout: 5))
        secondConfirmAlert.buttons["Delete"].tap()

        XCTAssertTrue(
            listRow.waitForNonExistence(timeout: 5),
            "confirming delete should remove the list from Home"
        )
    }
}

private extension XCUIElement {
    /// The inverse of `waitForExistence` — waits until the element is
    /// gone rather than present, for asserting something was removed.
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
