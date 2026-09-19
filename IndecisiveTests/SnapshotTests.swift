import XCTest
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import Indecisive

/// PLAN.md Phase 7: {Home, Detail, Reveal} × {every skin} × {default, XXL Dynamic
/// Type}, rendered at the design's own 393×852 frame so they can be compared
/// by eye against the mockups.
///
/// Every snapshot renders with `accessibilityReduceMotion` forced on. Not a
/// compromise — several components (`HeroBadge`, `PrimaryCTAGlyph`, and
/// everything in `RevealCentrepiece`) run `repeatForever`/`asyncAfter`-timed
/// animations that would otherwise make the captured frame depend on exactly
/// how long the run loop happened to pump before the image was grabbed,
/// which is inherently non-deterministic. Reduce Motion collapses each of
/// them straight to its resting pose — which is also the correct pose to
/// hold up against the mockups, since those are static images too.
@MainActor
final class SnapshotTests: XCTestCase {

    private let allSkins = [Skin.eightBall, Skin.prizeWheel]
    private let sizes: [(name: String, category: UIContentSizeCategory)] = [
        ("default", .large),
        ("xxl", .extraExtraExtraLarge),
    ]
    private let frame = SwiftUISnapshotLayout.fixed(width: 393, height: 852)

    private func traits(_ category: UIContentSizeCategory) -> UITraitCollection {
        UITraitCollection(preferredContentSizeCategory: category)
    }

    // MARK: Fixtures

    /// A "Lunch Places"-equivalent list with the same six items as the
    /// design mockup and `SeedData`, plus the other four sample lists, in a
    /// fresh in-memory store — matches what a real first launch looks like.
    private func makeHomeContainer() throws -> ModelContainer {
        let container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let lunch = PickList(name: "Lunch Places", flavorIndex: 0, sortOrder: 0)
        lunch.items = [
            PickItem(name: "Taco Truck on 9th", sortOrder: 0),
            PickItem(name: "Sushi Counter", sortOrder: 1),
            PickItem(name: "Pho Palace", sortOrder: 2),
            PickItem(name: "Green Bowl Salads", sortOrder: 3),
            PickItem(name: "Big Jim's Burgers", sortOrder: 4),
            PickItem(name: "The Dumpling Cart", sortOrder: 5),
        ]
        context.insert(lunch)
        for (i, name) in ["Movie Night", "Next Book to Read", "Makeup of the Day", "Weekend Adventure"].enumerated() {
            context.insert(PickList(name: name, flavorIndex: i + 1, sortOrder: i + 1))
        }
        try context.save()
        return container
    }

    /// Same six-item list, standalone, for Detail.
    private func makeDetailList() throws -> (container: ModelContainer, list: PickList) {
        let container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let list = PickList(name: "Lunch Places", flavorIndex: 0, sortOrder: 0)
        list.items = [
            PickItem(name: "Taco Truck on 9th", sortOrder: 0),
            PickItem(name: "Sushi Counter", sortOrder: 1),
            PickItem(name: "Pho Palace", sortOrder: 2),
            PickItem(name: "Green Bowl Salads", sortOrder: 3),
            PickItem(name: "Big Jim's Burgers", sortOrder: 4),
            PickItem(name: "The Dumpling Cart", sortOrder: 5),
        ]
        context.insert(list)
        try context.save()
        return (container, list)
    }

    /// A single-item list for Reveal: `PickService.pick` is genuinely
    /// random, and a 6-item list would make the winner (and therefore the
    /// whole rendered frame) different every run. One item removes the
    /// randomness entirely rather than fighting it — this doubles as real
    /// coverage of the one-item case the design's copy already accounts
    /// for ("Chosen out of 1. No takebacks.").
    private func makeRevealModel() throws -> (container: ModelContainer, model: RevealModel) {
        let container = try TestSupport.makeInMemoryContainer()
        let context = container.mainContext
        let list = PickList(name: "Lunch Places", flavorIndex: 0, sortOrder: 0)
        list.items = [PickItem(name: "Pho Palace", sortOrder: 0)]
        context.insert(list)
        try context.save()
        let service = PickService(context: context)
        let model = try XCTUnwrap(RevealModel(list: list, service: service))
        return (container, model)
    }

    // MARK: Home

    func testHomeSnapshots() throws {
        for skin in allSkins {
            let container = try makeHomeContainer()
            for (sizeName, category) in sizes {
                let view = HomeView()
                    .modelContainer(container)
                    .skin(skin)
                    .environment(\.indDisableIdleAnimationsForTesting, true)
                assertSnapshot(
                    of: view,
                    as: .image(layout: frame, traits: traits(category)),
                    named: "\(skin.id.rawValue)-\(sizeName)"
                )
            }
        }
    }

    // MARK: Detail

    func testDetailSnapshots() throws {
        for skin in allSkins {
            let (container, list) = try makeDetailList()
            for (sizeName, category) in sizes {
                let view = NavigationStack { ListDetailView(list: list) }
                    .modelContainer(container)
                    .skin(skin)
                    .environment(\.indDisableIdleAnimationsForTesting, true)
                assertSnapshot(
                    of: view,
                    as: .image(layout: frame, traits: traits(category)),
                    named: "\(skin.id.rawValue)-\(sizeName)"
                )
            }
        }
    }

    // MARK: Reveal

    func testRevealSnapshots() throws {
        for skin in allSkins {
            let (container, model) = try makeRevealModel()
            for (sizeName, category) in sizes {
                let view = RevealView(model: model)
                    .modelContainer(container)
                    .skin(skin)
                    .environment(\.indDisableIdleAnimationsForTesting, true)
                assertSnapshot(
                    of: view,
                    as: .image(layout: frame, traits: traits(category)),
                    named: "\(skin.id.rawValue)-\(sizeName)"
                )
            }
        }
    }
}
