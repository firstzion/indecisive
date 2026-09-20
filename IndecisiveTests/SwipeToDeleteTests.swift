import XCTest
import SwiftUI
@testable import IndecisiveKit

/// The decisions a Home-row swipe makes. They used to live inline in
/// `SwipeToDeleteRow`'s gesture callbacks, where nothing could reach them —
/// the gesture is the one interaction in the app with no unit coverage at
/// all, and only the UI test's `swipeLeft()` ever exercised it.
final class SwipeToDeleteTests: XCTestCase {

    private func drag(_ width: CGFloat, _ height: CGFloat) -> CGSize {
        CGSize(width: width, height: height)
    }

    // MARK: Which drags are row swipes

    func testADragThatMovesFurtherAcrossThanDownIsARowSwipe() {
        XCTAssertTrue(SwipeToDelete.isHorizontal(drag(-60, 10)))
        XCTAssertTrue(SwipeToDelete.isHorizontal(drag(40, -12)))
    }

    func testADragThatMovesFurtherDownThanAcrossIsLeftToTheScrollView() {
        XCTAssertFalse(SwipeToDelete.isHorizontal(drag(-10, 60)))
        XCTAssertFalse(SwipeToDelete.isHorizontal(drag(8, -40)))
        // A perfect diagonal isn't a swipe either — scrolling wins the tie,
        // since that's the gesture the whole screen is built around.
        XCTAssertFalse(SwipeToDelete.isHorizontal(drag(-30, 30)))
    }

    // MARK: How far the row follows

    func testTheRowFollowsALeftwardDrag() {
        XCTAssertEqual(SwipeToDelete.offset(for: drag(-80, 0)), -80)
    }

    func testTheRowDoesNotFollowARightwardDrag() {
        // There is nothing revealed to the right, so it stays put.
        XCTAssertEqual(SwipeToDelete.offset(for: drag(120, 0)), 0)
    }

    // MARK: When a release asks to delete

    func testReleasingPastTheThresholdAsksToDelete() {
        XCTAssertTrue(SwipeToDelete.commits(drag(SwipeToDelete.commitThreshold - 1, 0)))
        XCTAssertTrue(SwipeToDelete.commits(drag(-300, 0)))
    }

    func testReleasingShortOfTheThresholdDoesNothing() {
        XCTAssertFalse(SwipeToDelete.commits(drag(SwipeToDelete.commitThreshold, 0)))
        XCTAssertFalse(SwipeToDelete.commits(drag(SwipeToDelete.commitThreshold + 1, 0)))
        XCTAssertFalse(SwipeToDelete.commits(drag(-10, 0)))
    }

    func testDraggingRightNeverAsksToDelete() {
        XCTAssertFalse(SwipeToDelete.commits(drag(300, 0)))
    }

    func testTheThresholdStaysWellInsideAUITestSwipe() {
        // `XCUIElement.swipeLeft()` travels ~80 % of the element's width.
        // On the narrowest phone this app supports that is comfortably past
        // the threshold — if it weren't, the UI test that exercises this
        // gesture would commit only sometimes.
        let narrowestRowWidth: CGFloat = 320 - 40   // iPhone SE, minus the screen's horizontal padding
        XCTAssertTrue(
            SwipeToDelete.commits(drag(-0.8 * narrowestRowWidth, 0)),
            "a standard UI-test swipe must clear the commit threshold even on the narrowest supported screen"
        )
    }
}
