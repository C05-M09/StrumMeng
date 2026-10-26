import SwiftData

/// Lists every schema version in order. There is only V1 so far, hence no stages.
enum SessionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
