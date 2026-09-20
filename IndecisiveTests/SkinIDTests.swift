import XCTest
@testable import IndecisiveKit

final class SkinIDTests: XCTestCase {

    func testStoredValueThatNamesASkinResolvesToThatSkin() {
        for id in SkinID.allCases {
            XCTAssertEqual(SkinID.resolving(id.rawValue), id)
        }
    }

    func testStoredValueThatNoLongerNamesASkinResolvesToTheDefault() {
        // "gumball" was a shipped skin's raw value before it was removed, so
        // a device that had it selected still has that string saved under
        // `SkinID.storageKey`. It has to land on a real skin, not on nothing.
        XCTAssertEqual(SkinID.resolving("gumball"), SkinID.defaultID)
        XCTAssertEqual(SkinID.resolving(""), SkinID.defaultID)
    }
}
