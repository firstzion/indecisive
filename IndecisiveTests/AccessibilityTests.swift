import XCTest
import SwiftUI
import SwiftData
@testable import IndecisiveKit

/// What assistive technology is offered, read from SwiftUI's own accessibility tree.
///
/// XCUITest can find labels but can neither list nor invoke custom actions, so a
/// removed "Delete" action on a Home row — the only way VoiceOver or Switch
/// Control can delete a list from there — would go unnoticed. These walk the
/// tree in-process instead.
///
/// SwiftUI only builds that tree once an accessibility client is attached, which
/// UI automation does by setting an internal flag. These set the same flag
/// through libAccessibility — a private symbol, so if a future OS removes it the
/// tests skip (with a message) rather than fail.
@MainActor
final class AccessibilityTests: XCTestCase {

    private typealias SetAutomationEnabled = @convention(c) (Bool) -> Void

    private static let setAutomationEnabled: SetAutomationEnabled? = {
        guard let handle = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
            let symbol = dlsym(handle, "_AXSSetAutomationEnabled")
        else { return nil }
        return unsafeBitCast(symbol, to: SetAutomationEnabled.self)
    }()

    // The async `setUp`/`tearDown`, not the `…WithError` ones: XCTest runs them on
    // the main actor, where this class and the views it hosts live.
    override func setUp() async throws {
        guard let set = Self.setAutomationEnabled else {
            throw XCTSkip(
                "libAccessibility's _AXSSetAutomationEnabled isn't available on this OS, so SwiftUI's accessibility tree can't be read in-process"
            )
        }
        set(true)
    }

    override func tearDown() async throws {
        // Off again, so later tests in this process run as they always did.
        Self.setAutomationEnabled?(false)
    }

    private struct Node {
        let label: String
        let actions: [String]
    }

    /// Hosts `view` in a window and returns its accessibility nodes, waiting (up
    /// to 3 s) until `ready` says the tree has filled in — SwiftUI builds it, and
    /// `@Query` fills the rows, over a few run-loop turns.
    private func accessibilityNodes<V: View>(of view: V, until ready: ([Node]) -> Bool) -> [Node] {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        func children(of object: NSObject) -> [NSObject] {
            if let elements = object.accessibilityElements as? [NSObject], !elements.isEmpty { return elements }
            let count = object.accessibilityElementCount()
            if count != NSNotFound, count > 0 {
                return (0..<count).compactMap { object.accessibilityElement(at: $0) as? NSObject }
            }
            return (object as? UIView)?.subviews ?? []
        }
        func collect(_ object: NSObject, into nodes: inout [Node]) {
            let actions = (object.accessibilityCustomActions ?? []).map(\.name)
            if object.isAccessibilityElement || !actions.isEmpty {
                nodes.append(Node(label: object.accessibilityLabel ?? "", actions: actions))
            }
            for child in children(of: object) { collect(child, into: &nodes) }
        }

        var nodes: [Node] = []
        let deadline = Date().addingTimeInterval(3)
        repeat {
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            nodes = []
            collect(host.view, into: &nodes)
        } while !ready(nodes) && Date() < deadline
        return nodes
    }

    // MARK: Home

    /// This hosts the row the way `HomeView` composes it, rather than hosting
    /// `HomeView` itself.
    ///
    /// It used to host the whole screen, which worked only because the unit
    /// tests ran inside the app. Now that they link `IndecisiveKit` directly
    /// there is no host application, and a `NavigationStack` put into a
    /// plain `UIWindow` never runs its appearance transition: its
    /// `UINavigationTransitionView` stays empty, so Home's content is never
    /// built and the tree comes back with nothing in it. (Rendering is
    /// unaffected — the snapshot tests go through the library's own hosting
    /// and still draw the full screen.) Forcing the transition by hand
    /// doesn't help.
    ///
    /// What this test is actually about is the row: that the delete a swipe
    /// offers is also offered as a named action, because swiping is a gesture
    /// VoiceOver and Switch Control can't perform. That property belongs to
    /// `SwipeToDeleteRow` + `ListCard`, and is tested here directly. That
    /// `HomeView` really does wrap its rows this way is covered end to end by
    /// `HappyPathTests.testSwipeToDeleteListAsksForConfirmationFirst`.
    func testHomeRowOffersADeleteActionToAssistiveTechnology() throws {
        let list = PickList(name: "Lunch Places", flavorIndex: 0, sortOrder: 0)
        list.items = [PickItem(name: "Pho Palace", sortOrder: 0)]

        let row = SwipeToDeleteRow(skin: .prizeWheel, onDeleteRequested: {}) {
            ListCard(skin: .prizeWheel, list: list)
        }
        let nodes = accessibilityNodes(of: row) { $0.contains { $0.label.hasPrefix("Lunch Places") } }

        let card = try XCTUnwrap(nodes.first { $0.label.hasPrefix("Lunch Places") }, "the row should expose the list")
        XCTAssertEqual(
            card.actions, ["Delete"],
            "swiping is the only sighted way to delete a list here; VoiceOver and Switch Control need the same request as an action")
    }

    // MARK: Item rows in edit mode

    private func editModeRow(named name: String) -> ItemRow {
        ItemRow(
            skin: .prizeWheel, item: PickItem(name: name, sortOrder: 2), index: 2, isEditing: true,
            canMoveUp: true, canMoveDown: true, onDelete: {}, onMoveUp: {}, onMoveDown: {}
        )
    }

    func testEditModeControlsNameTheItemTheyActOn() {
        let nodes = accessibilityNodes(of: editModeRow(named: "Pho Palace")) { $0.count >= 3 }
        let labels = Set(nodes.map(\.label))
        for expected in ["Delete Pho Palace", "Move Pho Palace up", "Move Pho Palace down"] {
            XCTAssertTrue(labels.contains(expected), "expected a control labelled '\(expected)' — found \(labels.sorted())")
        }
    }

    func testEditModeControlsNeverReadAsAnEmptyName() {
        // Backspacing a name to retype it passes through an empty field; a label
        // reading "Delete " with nothing after it would be worse than useless.
        let nodes = accessibilityNodes(of: editModeRow(named: "")) { $0.count >= 3 }
        let labels = Set(nodes.map(\.label))
        XCTAssertTrue(labels.contains("Delete untitled item"), "found \(labels.sorted())")
        XCTAssertFalse(labels.contains { $0.hasSuffix(" ") }, "no label should end mid-sentence: \(labels.sorted())")
    }
}
