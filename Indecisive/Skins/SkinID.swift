import Foundation

/// The three selectable visual "skins". See PLAN.md §4 for the full token
/// tables this drives.
enum SkinID: String, CaseIterable, Identifiable, Codable {
    case gumball
    case eightBall
    case prizeWheel

    var id: String { rawValue }
}

extension SkinID {
    /// The skin used before the user has ever chosen one.
    static let defaultID: SkinID = .prizeWheel

    /// `@AppStorage`/`UserDefaults` key for the user's chosen skin.
    /// Shared here — rather than each call site re-typing `"skin"` — so
    /// `AppRoot` and `SkinPickerSheet` can't silently drift apart on the
    /// key string or the default value.
    ///
    /// Also referenced (necessarily as a plain string literal, since
    /// launch arguments aren't Swift code) by the UI tests'
    /// `-skin gumball` launch argument — keep that in sync if this ever
    /// changes. See `IndecisiveApp.isUITesting`.
    static let storageKey = "skin"

    /// `@AppStorage`/`UserDefaults` key for whether onboarding (or the
    /// Skins sheet) has ever picked a skin — see `AppRoot`. Also
    /// referenced by the UI tests' `-hasChosenSkin YES` launch argument;
    /// keep that in sync if this ever changes.
    static let hasChosenStorageKey = "hasChosenSkin"
}
