import Foundation
import SwiftData

/// The running total of picks across every list, kept as a *count* rather
/// than as a copy of every row.
///
/// Home's footer shows it — the 8-Ball's "THE BALL HAS SPOKEN {n} TIMES".
/// That line has now had three implementations, and it's worth saying what
/// each got wrong, because the two properties it needs pull against each
/// other:
///
/// 1. `PickService.totalPickCount`, a plain `fetchCount` read from `body`.
///    Cheap, but untracked: nothing told SwiftUI to re-render when a pick
///    was recorded over on the reveal screen, so the footer went stale.
/// 2. `@Query private var picks: [Pick]` plus `picks.count`. Correctly live,
///    but it materialises the entire pick history — every row ever written,
///    re-fetched on every change — to render one line of text. Nothing
///    prunes `Pick` rows, so that grows for the life of the install.
/// 3. This: `fetchCount` (a number from the store, not objects) re-run
///    whenever the store saves. Live *and* O(1) in what it brings back.
///
/// The refresh deliberately happens on a later turn of the main actor rather
/// than synchronously inside the notification, so nothing here calls back
/// into SwiftData while it is mid-save.
@Observable
@MainActor
final class PickCounter {
    private(set) var total = 0

    @ObservationIgnored private let context: ModelContext

    /// Kept so the observer can be torn down with this object. `deinit` is
    /// nonisolated, hence `nonisolated(unsafe)`: the token is written once
    /// during `init` on the main actor and read once during `deinit`, when
    /// by definition nothing else holds a reference to it.
    @ObservationIgnored nonisolated(unsafe) private var observer: (any NSObjectProtocol)?

    init(context: ModelContext) {
        self.context = context
        watchForSaves()
        refresh()
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    /// Re-reads the count. Cheap: `fetchCount` asks the store how many rows
    /// match, and never loads them.
    func refresh() {
        total = (try? context.fetchCount(FetchDescriptor<Pick>())) ?? 0
    }

    /// Keeps `total` current as picks are recorded elsewhere — chiefly the
    /// reveal screen, which is a `fullScreenCover` over Home.
    ///
    /// Registration is synchronous, which matters more than it looks.
    /// Written first as `Task { for await … in
    /// NotificationCenter.default.notifications(named:) }`, it had a race
    /// that the tests caught: a `Task` body doesn't begin until a later
    /// turn, so any save landing between `init` and the loop actually
    /// subscribing was missed, and the total then stayed wrong until the
    /// *next* save. `addObserver` is subscribed by the time `init` returns.
    ///
    /// The refresh itself still happens a hop later, so that nothing here
    /// re-enters SwiftData while it is in the middle of a save.
    private func watchForSaves() {
        observer = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }
}
