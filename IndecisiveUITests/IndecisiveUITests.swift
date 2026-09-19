import XCTest

final class IndecisiveUITests: XCTestCase {
    func testAppLaunches() throws {
        let app = XCUIApplication()
        // Without `-UITesting` this ran against the real on-disk store —
        // whatever manual testing left behind — instead of a clean,
        // seeded-fresh in-memory one. See `IndecisiveApp.isUITesting`.
        app.launchArguments = ["-UITesting", "-skin", "gumball", "-hasChosenSkin", "YES"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Rand-o-matic"].waitForExistence(timeout: 5))
    }
}
