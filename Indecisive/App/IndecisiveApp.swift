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
    /// UI tests also pass `-skin prizeWheel -hasChosenSkin YES` so every run
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

    /// `true` when this process is hosting a **unit** test run.
    ///
    /// `IndecisiveTests` is hosted by the real app, so launching it also
    /// launches the whole app: `SeedData` writes to the real on-disk store,
    /// and Home's `@Query` views sit there live, observing it, for the
    /// duration of the run — alongside every in-memory container the tests
    /// themselves create and save. That is incidental state no test asked
    /// for, and it is the leading suspect for the intermittent
    /// `EXC_BREAKPOINT` inside a `_SwiftData_SwiftUI` save observer that a
    /// full run hits every twenty-odd times (REVIEW.md, P1-5). So under a
    /// unit test run the app stays out of the way entirely: a throwaway
    /// in-memory store and no UI at all.
    ///
    /// XCTest sets this variable in the *host* app's environment. A UI
    /// test's target app doesn't get it — only the runner does — so
    /// `IndecisiveUITests` still launches the real app normally.
    private static var isHostingUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Either flavour of test run, both of which want a throwaway store
    /// rather than the user's real one.
    private static var isUnderTest: Bool {
        isUITesting || isHostingUnitTests
    }

    /// Where every `@AppStorage` in the app reads and writes — injected in
    /// `body` with `.defaultAppStorage(_:)`, so no call site has to know.
    let storage: UserDefaults

    private static let uiTestingSuiteName = "com.indecisive.app.uitesting"

    /// The app's own defaults normally; under `-UITesting`, a separate suite
    /// emptied at every launch.
    ///
    /// The skin choice was the one piece of state a UI test run still
    /// leaked. `-UITesting` already guarantees the *store* never touches
    /// real data, but the chosen skin lives in `UserDefaults`, and the
    /// happy-path test deliberately does *not* pin `-skin` — it switches
    /// skins, and a pinned argument-domain value would shadow the switch and
    /// make the test unable to fail. So the switch was real and persistent:
    /// it wrote the simulator's actual defaults. The test put the Wheel back
    /// at the end, but only if it got that far; any failure before that left
    /// the machine on the 8-Ball, and the next run — or the next manual
    /// launch — started somewhere else.
    ///
    /// A throwaway suite keeps the switch completely real while making the
    /// leak impossible, and means a test no longer has to tidy up after
    /// itself to stay honest. Launch arguments still work: `-key value` goes
    /// into the argument domain, which every `UserDefaults` instance
    /// searches first.
    private static func makeStorage() -> UserDefaults {
        guard isUITesting, let suite = UserDefaults(suiteName: uiTestingSuiteName) else {
            return .standard
        }
        suite.removePersistentDomain(forName: uiTestingSuiteName)
        return suite
    }

    init() {
        FontRegistry.verifyAllResolve()

        storage = Self.makeStorage()

        let schema = Schema(versionedSchema: IndecisiveSchemaV1.self)

        if Self.isUnderTest {
            // A test run's in-memory store is thrown away every launch
            // anyway, so there's nothing meaningful to fall back *from* —
            // a failure here means something is fundamentally broken
            // (not a real-world migration/corruption case), so this one
            // path keeps the hard `fatalError` rather than masking it.
            do {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                container = try ModelContainer(for: schema, migrationPlan: IndecisiveMigrationPlan.self, configurations: config)
            } catch {
                fatalError("Failed to create the in-memory test ModelContainer: \(error)")
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
            if Self.isHostingUnitTests {
                // Nothing at all while hosting unit tests — see
                // `isHostingUnitTests`. The tests that exercise real screens
                // host their own copies, with their own containers; the
                // app's would only be a second, unasked-for set of live
                // `@Query` observers in the same process.
                Color.clear
            } else {
                AppRoot()
                    .environment(\.didFailToLoadPersistedStore, didFailToLoadPersistedStore)
                    .defaultAppStorage(storage)
            }
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
