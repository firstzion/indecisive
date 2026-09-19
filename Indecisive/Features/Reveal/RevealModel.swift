import Foundation
import SwiftData

/// Drives one reveal session: holds the current winner, tracks who's been
/// rejected so a re-roll never immediately repeats them, and records every
/// pick (accepted or not) through `PickService`.
@Observable
final class RevealModel: Identifiable {
    let id = UUID()
    let list: PickList
    private let service: PickService
    private(set) var winner: PickItem
    /// Bumped on every `reroll()`, even when the freshly-picked winner
    /// happens to be the same item as before — a one-item list, or the
    /// exclusion pool resetting because every candidate had just been
    /// rejected (see `PickService.choose`). `winner.id` alone wouldn't
    /// change in that case, so the reveal screen keys its intro-animation
    /// replay and VoiceOver announcement off this token instead — a
    /// same-winner reroll should still visibly and audibly do something,
    /// not silently look like a tap that did nothing.
    private(set) var rerollToken = UUID()
    private var rejectedIDs: Set<PersistentIdentifier> = []

    /// Fails if the list has no items — callers should already be guarding
    /// against this (the CTA is disabled on an empty list), but this makes
    /// "no items" a non-event instead of a crash if it ever happens anyway.
    init?(list: PickList, service: PickService) {
        guard let first = service.pick(from: list) else { return nil }
        self.list = list
        self.service = service
        self.winner = first
    }

    /// "Sold, let's go" / "LOCK IT IN": records the win and ends the session.
    func accept() {
        service.record(winner, in: list, accepted: true)
    }

    /// "Nope, roll again" / "SHAKE AGAIN" / "SPIN AGAIN": records the
    /// rejection, excludes this winner, and re-picks. If every item has now
    /// been rejected, `PickService` resets the pool rather than getting
    /// stuck — see `PickService.choose`.
    func reroll() {
        service.record(winner, in: list, accepted: false)
        rejectedIDs.insert(winner.persistentModelID)
        if let next = service.pick(from: list, excluding: rejectedIDs) {
            winner = next
        }
        rerollToken = UUID()
    }
}
