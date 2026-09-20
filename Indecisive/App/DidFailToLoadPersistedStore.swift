import SwiftUI

private struct DidFailToLoadPersistedStoreKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// `true` when the real persisted store couldn't be opened at all (a
    /// failed migration, disk corruption, …) and the app fell back to a
    /// fresh, throwaway in-memory one instead.
    ///
    /// Written once at launch by `IndecisiveApp`, which owns the container
    /// and is the only thing that can know; read by `HomeView`, which tells
    /// the user their lists may be gone rather than silently starting them
    /// over with no explanation.
    ///
    /// It lives in its own file, in `IndecisiveKit`, because those two ends
    /// are now in different modules: the `@main` App struct is the app
    /// target's only source file, and everything it talks to has to be
    /// reachable from here.
    var didFailToLoadPersistedStore: Bool {
        get { self[DidFailToLoadPersistedStoreKey.self] }
        set { self[DidFailToLoadPersistedStoreKey.self] = newValue }
    }
}
