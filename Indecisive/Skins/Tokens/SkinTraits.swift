import Foundation

/// What a skin *does*, as opposed to how it looks: the behaviours that differ
/// between skins. Each one is a named field here rather than an
/// `if skin.id == …` where it's used, so a new skin has to answer the question
/// instead of silently inheriting a default.
struct SkinTraits: Sendable {
    /// The 8-Ball's "ASK. SHAKE. OBEY.": shaking the phone picks (on a list) and
    /// re-rolls (on the reveal) instead of tapping. The other skins ignore a
    /// shake. `ListDetailView` and `RevealView` both read this, so the two can't
    /// disagree.
    let shakeToPick: Bool
}
