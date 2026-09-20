import XCTest
@testable import IndecisiveKit

final class WheelShapeTests: XCTestCase {

    func testWedgeCountCapsAtEightAndFloorsAtOne() {
        XCTAssertEqual(wheelWedgeCount(forItemCount: 3), 3)
        XCTAssertEqual(wheelWedgeCount(forItemCount: 8), 8)
        XCTAssertEqual(wheelWedgeCount(forItemCount: 23), 8, "capped so the wheel stays legible")
        XCTAssertEqual(wheelWedgeCount(forItemCount: 0), 1, "a 0-wedge wheel can't be drawn")
    }

    func testExtraSpinsAddFullThreeSixtyTurns() {
        let base = wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 0, extraSpins: 0)
        let withFourSpins = wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 0, extraSpins: 4)
        XCTAssertEqual(withFourSpins - base, 4 * 360, accuracy: 0.001)
    }

    func testWinnerIndexBeyondWedgeCountWrapsToTheSameWedge() {
        // Can happen for a list with more items than the 8-wedge cap: the
        // winner's position in the list can exceed wedgeCount.
        let a = wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 1, extraSpins: 0)
        let b = wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 5, extraSpins: 0)
        XCTAssertEqual(a, b, accuracy: 0.001)
    }

    func testEveryWedgeIndexProducesADistinctTargetWithinOneFullTurn() {
        let wedgeCount = 6
        var targets: Set<Int> = []
        for index in 0..<wedgeCount {
            let target = wheelTargetSpinAngle(wedgeCount: wedgeCount, winnerIndex: index, extraSpins: 0)
            targets.insert(Int((target).rounded()))
        }
        XCTAssertEqual(targets.count, wedgeCount, "each wedge should land at its own distinct angle")
    }

    func testZeroWedgeCountDoesNotCrashOrDivideByZero() {
        XCTAssertEqual(wheelTargetSpinAngle(wedgeCount: 0, winnerIndex: 0, extraSpins: 2), 720)
    }

    /// Concrete values, verified against `WheelFill`'s actual rendering
    /// (not just re-derived by hand) — a wedge's *center* has to land
    /// under the pointer, not a neighboring wedge or the boundary between
    /// two. A previous version of this function was off by a constant
    /// 90°, which for a 4-wedge wheel silently landed the *previous*
    /// wedge instead — every other test above still passed, since none of
    /// them pin an absolute angle.
    func testTargetAngleCentersTheWinningWedgeExactlyUnderThePointer() {
        XCTAssertEqual(wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 0, extraSpins: 0), -45, accuracy: 0.001)
        XCTAssertEqual(wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 1, extraSpins: 0), -135, accuracy: 0.001)
        XCTAssertEqual(wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 2, extraSpins: 0), -225, accuracy: 0.001)
        XCTAssertEqual(wheelTargetSpinAngle(wedgeCount: 4, winnerIndex: 3, extraSpins: 0), -315, accuracy: 0.001)
    }
}
