import Foundation
import os

/// The app's loggers, one per area.
///
/// There was no logging anywhere before this — the only diagnostics were three
/// `print`s, two of them behind `#if DEBUG` and one on a release path. That
/// last one matters: it reports the store failing to open, which is the single
/// worst thing that can happen to this app, and `print` goes nowhere a shipped
/// build can be inspected from. A failure in the field was invisible.
///
/// `Logger` writes to the unified log, so the same call is visible in Xcode
/// during development and in Console.app (or `log collect` from a sysdiagnose)
/// for a build already on someone's phone.
///
/// Nothing here interpolates user data. Strings in a `Logger` call are redacted
/// as `<private>` by default unless marked `.public`, which is the right
/// default for a list of someone's lunch choices — but the rule only helps if
/// no one hand-builds a message out of them first.
public enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.indecisive.app"

    /// Opening, migrating and falling back on the SwiftData store.
    public static let store = Logger(subsystem: subsystem, category: "store")

    /// Registering and resolving the bundled fonts.
    public static let fonts = Logger(subsystem: subsystem, category: "fonts")
}
