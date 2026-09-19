import SwiftUI
import SwiftData

@main
struct IndecisiveApp: App {
    let container: ModelContainer
    /// `true` when the real persisted store couldn't be opened at all (a
    /// failed migration, disk corruption, …) and we fell back to a fresh,
    /// throwaway in-memory one instead — see the `catch` in `init()`.
    /// Surfaced to `HomeView` so the user finds out their lists may be
    /// gone, rather than the app silently starting them over with no
    /// explanation.
    let didFailToLoadPersistedStore: Bool

    /// Launch with `-UITesting` to get a deterministic starting state: an
    /// in-memory store (so a test run never touches, or depends on, real
    /// persisted app data — including whatever's left over from manual
    /// testing in the simulator) seeded fresh every launch.
    ///
    /// UI tests also pass `-skin gumball -hasChosenSkin YES` so every run
    /// starts on the same skin with onboarding already complete,
    /// regardless of whatever was last selected. Those two are picked up
    /// automatically by `@AppStorage`/`UserDefaults` — a `-key value`
    /// launch argument lands in `UserDefaults`' argument domain, which
    /// outranks the real persisted value for the lifetime of the process
    /// without ever writing to disk. (An earlier version of this instead
    /// called `UserDefaults.standard.set(...)` directly here, which *did*
    /// persist — silently overwriting the simulator's real skin choice on
    /// every test run, exactly the "never touches real app data" guarantee
    /// above promised not to do. Don't reintroduce that.)
    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    init() {
        FontRegistry.verifyAllResolve()

        let schema = Schema(versionedSchema: IndecisiveSchemaV1.self)

        if Self.isUITesting {
            // A UI test's in-memory store is thrown away every launch
            // anyway, so there's nothing meaningful to fall back *from* —
            // a failure here means something is fundamentally broken
            // (not a real-world migration/corruption case), so this one
            // path keeps the hard `fatalError` rather than masking it.
            do {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                container = try ModelContainer(for: schema, migrationPlan: IndecisiveMigrationPlan.self, configurations: config)
            } catch {
                fatalError("Failed to create the in-memory UI-test ModelContainer: \(error)")
            }
            didFailToLoadPersistedStore = false
        } else {
            do {
                container = try ModelContainer(
                    for: schema,
                    migrationPlan: IndecisiveMigrationPlan.self,
                    configurations: ModelConfiguration(schema: schema)
                )
                didFailToLoadPersistedStore = false
            } catch {
                // The persisted store couldn't be opened — a failed
                // migration, disk corruption, or similar. This used to be
                // a `fatalError`, which turns one bad store into an
                // unrecoverable launch loop: every relaunch hits the same
                // error and crashes again, with no way for the user to
                // recover short of deleting the app. Falling back to a
                // throwaway in-memory store at least gets them into a
                // working app; `didFailToLoadPersistedStore` lets
                // `HomeView` tell them what happened instead of silently
                // discarding their lists with no explanation.
                print("⚠️ Indecisive: failed to open the persisted store (\(error)); falling back to a temporary in-memory store.")
                guard let fallback = try? ModelContainer(
                    for: schema,
                    migrationPlan: IndecisiveMigrationPlan.self,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                ) else {
                    fatalError("Failed to create even a fallback in-memory ModelContainer: \(error)")
                }
                container = fallback
                didFailToLoadPersistedStore = true
            }
        }

        SeedData.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environment(\.didFailToLoadPersistedStore, didFailToLoadPersistedStore)
        }
        .modelContainer(container)
    }
}

private struct DidFailToLoadPersistedStoreKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// See `IndecisiveApp.didFailToLoadPersistedStore`.
    var didFailToLoadPersistedStore: Bool {
        get { self[DidFailToLoadPersistedStoreKey.self] }
        set { self[DidFailToLoadPersistedStoreKey.self] = newValue }
    }
}
