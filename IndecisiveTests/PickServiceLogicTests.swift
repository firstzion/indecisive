import XCTest
@testable import IndecisiveKit

/// Tests for `PickService.choose`, the pure random-selection algorithm.
/// Uses `SeededGenerator` throughout so every run is bit-for-bit
/// reproducible — no flaky statistical tests.
final class PickServiceLogicTests: XCTestCase {

    private struct Candidate: Identifiable, Equatable {
        let id: Int
        let name: String
    }

    private let candidates = [
        Candidate(id: 0, name: "Taco Truck"),
        Candidate(id: 1, name: "Sushi Counter"),
        Candidate(id: 2, name: "Pho Palace"),
        Candidate(id: 3, name: "Green Bowl Salads"),
        Candidate(id: 4, name: "Big Jim's Burgers"),
    ]

    func testEmptyListReturnsNil() {
        var rng = SeededGenerator(seed: 1)
        let result = PickService.choose(from: [Candidate](), excluding: [], using: &rng)
        XCTAssertNil(result)
    }

    func testSingleItemListAlwaysReturnsThatItem() {
        let only = [Candidate(id: 0, name: "Solo")]
        var rng = SeededGenerator(seed: 2)
        for _ in 0..<20 {
            let result = PickService.choose(from: only, excluding: [], using: &rng)
            XCTAssertEqual(result, only[0])
        }
    }

    func testSingleItemListResetsWhenTheOnlyItemIsExcluded() {
        // Simulates re-rolling when there's only one candidate: excluding it
        // exhausts the pool, so the exclusion set resets and it's picked again
        // rather than the call returning nil.
        let only = [Candidate(id: 0, name: "Solo")]
        var rng = SeededGenerator(seed: 3)
        let result = PickService.choose(from: only, excluding: [0], using: &rng)
        XCTAssertEqual(result, only[0])
    }

    func testRerollNeverReturnsAnExcludedID() {
        var rng = SeededGenerator(seed: 4)
        let excluded: Set<Int> = [2]  // "Pho Palace" was just rejected
        for _ in 0..<200 {
            let result = PickService.choose(from: candidates, excluding: excluded, using: &rng)
            XCTAssertNotEqual(result?.id, 2)
        }
    }

    func testResetsOnceEveryCandidateHasBeenExcluded() {
        var rng = SeededGenerator(seed: 5)
        let allIDs = Set(candidates.map(\.id))
        // Every candidate excluded -> pool is exhausted -> falls back to the
        // full candidate list rather than returning nil.
        for _ in 0..<50 {
            let result = PickService.choose(from: candidates, excluding: allIDs, using: &rng)
            XCTAssertNotNil(result)
            XCTAssertTrue(candidates.contains(result!))
        }
    }

    func testDistributionIsRoughlyUniform() {
        var rng = SeededGenerator(seed: 42)
        var counts: [Int: Int] = [:]
        let trials = 10_000
        for _ in 0..<trials {
            let result = PickService.choose(from: candidates, excluding: [], using: &rng)!
            counts[result.id, default: 0] += 1
        }
        // 5 candidates, 10,000 trials -> ~2,000 each. Allow a generous band
        // since this only needs to catch a badly broken (e.g. always-first)
        // implementation, not verify statistical rigor.
        let expected = Double(trials) / Double(candidates.count)
        for candidate in candidates {
            let count = Double(counts[candidate.id] ?? 0)
            XCTAssertEqual(
                count, expected, accuracy: expected * 0.25,
                "candidate \(candidate.name) was picked \(Int(count)) times, expected ~\(Int(expected))")
        }
    }
}
