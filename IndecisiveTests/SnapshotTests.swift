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
///
/// The reference images were recorded on an **iPhone 17 Pro running iOS 26.5**
/// (a 3× device: each PNG is 1179 × 2556). Run this on iOS 26.5 — see the
/// README. Other 3× iPhones at 26.5 match (an iPhone 17 was checked); iOS 27.0
/// does not: it lays out `NavigationStack` screens differently (Home and Detail
/// sit ~50 pt lower and Detail draws its toolbar), so 17 of the 18 images fail
/// there. If a UI change is deliberate, re-record the affected images in the
/// same commit as the change (README: "Snapshot tests"); a suite left red can't
/// tell an expected mismatch from a real regression.
@MainActor
final class SnapshotTests: XCTestCase {

    private let sizes: [(name: String, category: UIContentSizeCategory)] = [
        ("default", .large),
        ("xxl", .extraExtraExtraLarge),
    ]
    private let frame = SwiftUISnapshotLayout.fixed(width: 393, height: 852)

    private func traits(_ category: UIContentSizeCategory) -> UITraitCollection {
        UITraitCollection(preferredContentSizeCategory: category)
    }

    /// The one image strategy every snapshot below goes through, so the
    /// comparison tolerance is set in exactly one place.
    ///
    /// - `perceptualPrecision: 0.98` — a pixel matches if it is within ~2 ΔE
    ///   of its reference, about the smallest colour difference an eye can see.
    ///   That absorbs sub-visible anti-aliasing and gradient drift between
    ///   Xcode or simulator builds without letting a real colour change through.
    /// - `precision: 1` — every pixel must still clear that bar. Deliberately
    ///   *not* the common `0.99`: letting 1 % of the frame differ would have
    ///   passed the 8-Ball's row-index colour change, which touched only 0.11 %
    ///   of its Detail screenshot.
    private func screen<V: View>(_ category: UIContentSizeCategory) -> Snapshotting<V, UIImage> {
        .image(precision: 1, perceptualPrecision: 0.98, layout: frame, traits: traits(category))
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
        for skin in Skin.all {
            let container = try makeHomeContainer()
            for (sizeName, category) in sizes {
                let view = HomeView()
                    .modelContainer(container)
                    .skin(skin)
                    .environment(\.indDisableIdleAnimationsForTesting, true)
                assertSnapshot(
                    of: view,
                    as: screen(category),
                    named: "\(skin.id.rawValue)-\(sizeName)"
                )
            }
        }
    }

    // MARK: Detail

    func testDetailSnapshots() throws {
        for skin in Skin.all {
            let (container, list) = try makeDetailList()
            for (sizeName, category) in sizes {
                let view = NavigationStack { ListDetailView(list: list) }
                    .modelContainer(container)
                    .skin(skin)
                    .environment(\.indDisableIdleAnimationsForTesting, true)
                assertSnapshot(
                    of: view,
                    as: screen(category),
                    named: "\(skin.id.rawValue)-\(sizeName)"
                )
            }
        }
    }

    // MARK: Reveal

    func testRevealSnapshots() throws {
        for skin in Skin.all {
            let (container, model) = try makeRevealModel()
            for (sizeName, category) in sizes {
                let view = RevealView(model: model)
                    .modelContainer(container)
                    .skin(skin)
                    .environment(\.indDisableIdleAnimationsForTesting, true)
                assertSnapshot(
                    of: view,
                    as: screen(category),
                    named: "\(skin.id.rawValue)-\(sizeName)"
                )
            }
        }
    }
}
