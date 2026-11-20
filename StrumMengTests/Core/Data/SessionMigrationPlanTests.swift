import SwiftData
import XCTest
@testable import StrumMeng

/// Opens a store written by schema V1 the way the app does after an update, through the migration
/// plan, and checks the old record is still there (with no strums).
final class SessionMigrationPlanTests: XCTestCase {
    private var storeURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SessionMigrationPlanTests-\(UUID().uuidString).store")
    }

    override func tearDownWithError() throws {
        let directory = storeURL.deletingLastPathComponent()
        let name = storeURL.lastPathComponent
        for file in (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        where file.hasPrefix(name) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(file))
        }
        try super.tearDownWithError()
    }

    @MainActor
    func test_v1Store_opensAsV2_withTheOldRecordAndNoStrums() throws {
        let id = UUID()
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let container = try ModelContainer(for: schema,
                                               configurations: ModelConfiguration(schema: schema, url: storeURL))
            container.mainContext.insert(SchemaV1.PracticeSessionRecord(
                id: id, patternID: "foundation", songID: nil, bpm: 80, accuracy: 0.75,
                perfectCount: 6, tooEarlyCount: 1, missCount: 1,
                createdAt: Date(timeIntervalSince1970: 1_000), beatEventsData: Data("[]".utf8)))
            try container.mainContext.save()
        }

        let schema = Schema(versionedSchema: SchemaV2.self)
        let container = try ModelContainer(for: schema, migrationPlan: SessionMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: storeURL))
        let records = try container.mainContext.fetch(FetchDescriptor<SchemaV2.PracticeSessionRecord>())

        XCTAssertEqual(records.map(\.id), [id])
        let result = try SessionRecordMapper.makeResult(from: try XCTUnwrap(records.first))
        XCTAssertEqual(result.accuracy, 0.75)
        XCTAssertEqual(result.strums, [])
    }
}
