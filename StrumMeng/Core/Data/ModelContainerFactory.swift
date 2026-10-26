import SwiftData

/// Builds the one `ModelContainer` the app uses.
///
/// Tests and previews call this with `inMemory: true`, so they run against the same
/// schema and migration plan as production instead of a hand-rolled copy.
enum ModelContainerFactory {
    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: schema,
            migrationPlan: SessionMigrationPlan.self,
            configurations: configuration
        )
    }
}
