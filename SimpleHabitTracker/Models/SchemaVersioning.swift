import Foundation
import SwiftData

/// V1 baseline: the shipped 1.2.1 shape (CloudKit-compatible — inline attribute
/// defaults, optional relationships). Every future model change gets a new
/// VersionedSchema and a MigrationStage here instead of mutating models in place.
enum SimpleHabitsSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Habit.self, WeekRecord.self]
    }
}

enum SimpleHabitsMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SimpleHabitsSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
