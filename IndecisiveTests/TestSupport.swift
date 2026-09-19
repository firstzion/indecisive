import Foundation
import SwiftData
@testable import Indecisive

/// A fresh, isolated in-memory SwiftData store for each test that needs one —
/// nothing is written to disk and nothing leaks between tests.
enum TestSupport {
    static func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: PickList.self, PickItem.self, Pick.self,
            configurations: config
        )
    }

    static func makeInMemoryContext() throws -> ModelContext {
        ModelContext(try makeInMemoryContainer())
    }
}
