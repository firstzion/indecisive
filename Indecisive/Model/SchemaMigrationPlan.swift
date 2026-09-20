import Foundation
import SwiftData

/// The current (and, so far, only) shape of the persisted schema.
///
/// Every `@Model` type ships inside a `VersionedSchema` from here on, even
/// though there's only one version today — adding this now, while there's
/// nothing to migrate *from* yet, means the first real model change (a
/// renamed/added/removed property, a new model type, …) has an actual
/// migration path to slot into, instead of shipping against an unversioned
/// store that SwiftData has no story for upgrading later.
public enum IndecisiveSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [PickList.self, PickItem.self, Pick.self]
    }
}

/// No stages yet — there's only one schema version so far. The next model
/// change adds a `IndecisiveSchemaV2` and a `MigrationStage` here describing
/// how to get from V1 to V2, rather than starting this file from scratch.
public enum IndecisiveMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [IndecisiveSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
