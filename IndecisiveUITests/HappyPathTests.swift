import XCTest

/// PLAN.md Phase 7's end-to-end happy path: create a list, add 3 items,
/// pick, re-roll, accept, check the "last pick" line, switch skin, and
/// confirm the state survives the switch.
///
/// Launches with `-UITesting` (see `IndecisiveApp`), which forces an
/// in-memory store seeded fresh every run *and* points every `@AppStorage`
/// at a throwaway `UserDefaults` suite wiped on launch — so this test never
/// touches, or depends on, real persisted simulator data, the skin choice
/// included.
///
/// That last part used to be untrue: the happy path really does switch
/// skins, so it wrote the simulator's actual defaults and then put the Wheel
/// back at the end — which only helped if it got that far. It no longer has
/// to tidy up after itself, so a failure halfway through can't leave the
/// machine, or the next run, somewhere else.
@MainActor
final class HappyPathTests: XCTestCase {
    private var app: XCUIApplication!

    // The async `setUp` (not `setUpWithError`): XCTest runs it on the main
    // actor, where `XCUIApplication` and `app` live.
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Launches the app on `-UITesting`'s fresh in-memory store, with
    /// onboarding already complete (`-hasChosenSkin YES`).
    ///
    /// `pinningSkin` also passes `-skin prizeWheel`, so the run starts on the
    /// same skin whatever was last selected. Both flags land in
    /// `UserDefaults`' argument domain, which outranks anything the app
    /// writes for the lifetime of the process — handy for a fixed starting
    /// point, but it also means the skin *cannot be changed from the UI*
    /// while it is pinned. A test that switches skins must therefore not
    /// pin, and gets its fixed starting point by picking a skin through the
    /// UI instead.
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

        // Both buttons exist as soon as the reveal does, but stay disabled
        // until the skin's intro has finished and the winner is readable —
        // the Wheel's spin is 2.9 s of that. Waiting on `isEnabled` rather
        // than mere existence is what makes this a real check of that guard
        // instead of a tap that silently does nothing.
        let rerollButton = app.buttons["rerollButton"]
        XCTAssertTrue(rerollButton.waitForExistence(timeout: 5), "the reveal should appear after tapping Pick For Me")
        XCTAssertTrue(rerollButton.waitUntilEnabled(timeout: 10), "the re-roll button should become usable once the wheel lands")
        rerollButton.tap()

        let acceptButton = app.buttons["acceptButton"]
        XCTAssertTrue(acceptButton.waitForExistence(timeout: 5))
        XCTAssertTrue(acceptButton.waitUntilEnabled(timeout: 10), "the accept button should become usable once the re-rolled wheel lands")
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

    /// Edit mode end to end — nothing exercised it before. Reorders, deletes and
    /// renames items through the real controls, then checks the changes stick
    /// when the list is left and reopened. Also checks what VoiceOver is told:
    /// each control names the item it acts on, not just "minus circle" or
    /// "chevron up".
    func testEditModeReordersDeletesAndRenamesItems() throws {
        // Never touches the skin, so it can pin one for a uniform start.
        // `-UITesting` seeds "Lunch Places": Taco Truck on 9th, Sushi Counter,
        // Pho Palace, Green Bowl Salads, Big Jim's Burgers, The Dumpling Cart.
        launchApp(pinningSkin: true)
        app.buttons["listRow-Lunch Places"].tap()

        let editButton = app.buttons["editModeButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        func name(at index: Int) -> String? {
            app.textFields["itemNameField-\(index)"].value as? String
        }

        // MARK: What VoiceOver hears

        XCTAssertEqual(app.buttons["deleteItemButton-2"].label, "Delete Pho Palace")
        XCTAssertEqual(app.buttons["moveItemUpButton-2"].label, "Move Pho Palace up")
        XCTAssertEqual(app.buttons["moveItemDownButton-2"].label, "Move Pho Palace down")
        XCTAssertFalse(app.buttons["moveItemUpButton-0"].isEnabled, "the first item can't move up")
        XCTAssertFalse(app.buttons["moveItemDownButton-5"].isEnabled, "the last item can't move down")

        // MARK: Reorder — move the first item down one

        app.buttons["moveItemDownButton-0"].tap()
        XCTAssertEqual(name(at: 0), "Sushi Counter")
        XCTAssertEqual(name(at: 1), "Taco Truck on 9th")

        // MARK: Delete — Pho Palace is now third

        app.buttons["deleteItemButton-2"].tap()
        XCTAssertEqual(name(at: 2), "Green Bowl Salads", "the items below should close up")
        XCTAssertFalse(app.textFields["itemNameField-5"].exists, "six items minus one leaves five")

        // MARK: Rename — the keyboard comes up, so this goes last

        app.textFields["itemNameField-1"].clearAndTypeText("Taco Truck")
        // Tapping Done with a field still focused makes SwiftUI log "Modifying state
        // during view update" — a known, pre-existing quirk (REVIEW.md, P2-11) that
        // this realistic rename-then-Done path exercises. It's a log line, not a failure.
        editButton.tap() // now "Done"

        // MARK: Out of edit mode, and again after leaving and coming back

        func assertEditsShowing() {
            let taco = app.staticTexts["Taco Truck"]
            XCTAssertTrue(taco.waitForExistence(timeout: 5), "the renamed item should show")
            XCTAssertFalse(app.staticTexts["Taco Truck on 9th"].exists, "the old name should be gone")
            XCTAssertFalse(app.staticTexts["Pho Palace"].exists, "the deleted item should be gone")
            XCTAssertLessThan(app.staticTexts["Sushi Counter"].frame.minY, taco.frame.minY, "the reorder should stick")
        }
        assertEditsShowing()

        app.buttons["backToListsButton"].tap()
        let row = app.buttons["listRow-Lunch Places"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("5 wedges"), "Home should show the five that are left — got '\(row.label)'")
        row.tap()
        assertEditsShowing()
    }
}

private extension XCUIElement {
    /// Replaces a text field's contents: tap at its far right end (so the caret
    /// lands after whatever is there), delete that many characters, type the new text.
    func clearAndTypeText(_ text: String) {
        coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        let current = (value as? String) ?? ""
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text)
    }

    /// Waits until the element is present *and* enabled. `waitForExistence`
    /// alone isn't enough for a control that appears disabled and is
    /// switched on later — `tap()` on a disabled element succeeds and does
    /// nothing, so the failure would surface much later and somewhere else.
    func waitUntilEnabled(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// The inverse of `waitForExistence` — waits until the element is
    /// gone rather than present, for asserting something was removed.
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
