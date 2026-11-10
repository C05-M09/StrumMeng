import XCTest
@testable import StrumMeng

final class SessionHistoryTests: XCTestCase {
    func test_emptyDatabaseHasNoSavedSessions() async throws {
        let repository = SwiftDataSessionRepository(modelContainer: try ModelContainerFactory.make(inMemory: true))
        let exists = try await repository.hasSavedSessions()
        XCTAssertFalse(exists)
    }

    func test_recordFromAnyPatternOrSongCountsAsHistory() async throws {
        let repository = SwiftDataSessionRepository(modelContainer: try ModelContainerFactory.make(inMemory: true))
        let result = SessionResult(id: UUID(), patternID: "retired-pattern", songID: "future-song",
            bpm: 80, accuracy: 1, perfectCount: 8, tooEarlyCount: 0, missCount: 0,
            createdAt: Date(), beatEvents: [])
        try await repository.save(result)
        let exists = try await repository.hasSavedSessions()
        XCTAssertTrue(exists)
        let currentPatternRecords = try await repository.practiceRecords(forPattern: "foundation")
        XCTAssertTrue(currentPatternRecords.isEmpty)
    }
}
