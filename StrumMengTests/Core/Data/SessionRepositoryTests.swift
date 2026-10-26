import XCTest
@testable import StrumMeng

final class SessionRepositoryTests: XCTestCase {
    private func makeRepository() throws -> SwiftDataSessionRepository {
        let container = try ModelContainerFactory.make(inMemory: true)
        return SwiftDataSessionRepository(modelContainer: container)
    }

    private func makeResult(
        id: UUID = UUID(),
        patternID: String = "foundation",
        songID: String? = nil,
        bpm: Int = 80,
        accuracy: Double = 0.9,
        createdAt: Date = Date(timeIntervalSince1970: 1_000),
        beatEvents: [BeatEvent] = []
    ) -> SessionResult {
        SessionResult(
            id: id,
            patternID: patternID,
            songID: songID,
            bpm: bpm,
            accuracy: accuracy,
            perfectCount: 6,
            tooEarlyCount: 1,
            missCount: 1,
            createdAt: createdAt,
            beatEvents: beatEvents
        )
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    func test_save_thenFetch_roundTripsEveryField() async throws {
        let repository = try makeRepository()
        let saved = makeResult(beatEvents: [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 8),
            BeatEvent(stepIndex: 1, result: .miss, offsetMs: nil)
        ])

        try await repository.save(saved)
        let fetched = try await repository.practiceRecords(forPattern: "foundation")

        XCTAssertEqual(fetched, [saved])
    }

    func test_save_sameSessionTwice_storesItOnce() async throws {
        let repository = try makeRepository()
        let session = makeResult()

        try await repository.save(session)
        try await repository.save(session)
        let fetched = try await repository.practiceRecords(forPattern: "foundation")

        XCTAssertEqual(fetched.count, 1)
    }

    func test_practiceRecords_areSortedByAccuracyThenNewestFirst() async throws {
        let repository = try makeRepository()
        let low = makeResult(accuracy: 0.5, createdAt: date(4))
        let tiedOlder = makeResult(accuracy: 0.9, createdAt: date(2))
        let tiedNewer = makeResult(accuracy: 0.9, createdAt: date(3))
        let mid = makeResult(accuracy: 0.7, createdAt: date(1))

        for session in [low, tiedOlder, tiedNewer, mid] {
            try await repository.save(session)
        }
        let fetched = try await repository.practiceRecords(forPattern: "foundation")

        XCTAssertEqual(fetched.map(\.id), [tiedNewer.id, tiedOlder.id, mid.id, low.id])
    }

    func test_practiceRecords_excludeShowtimeSessions() async throws {
        let repository = try makeRepository()
        let practice = makeResult()
        let showtime = makeResult(songID: "twinkle")

        try await repository.save(practice)
        try await repository.save(showtime)
        let fetched = try await repository.practiceRecords(forPattern: "foundation")

        XCTAssertEqual(fetched.map(\.id), [practice.id])
    }

    func test_practiceRecords_onlyReturnTheRequestedPattern() async throws {
        let repository = try makeRepository()
        let foundation = makeResult(patternID: "foundation")
        let syncopation = makeResult(patternID: "syncopation")

        try await repository.save(foundation)
        try await repository.save(syncopation)
        let fetched = try await repository.practiceRecords(forPattern: "syncopation")

        XCTAssertEqual(fetched.map(\.id), [syncopation.id])
    }

    func test_practiceRecords_withNoSessions_isEmpty() async throws {
        let repository = try makeRepository()

        let fetched = try await repository.practiceRecords(forPattern: "foundation")

        XCTAssertTrue(fetched.isEmpty)
    }

    func test_lastPracticeBPM_isTheNewestPracticeSessionsBPM() async throws {
        let repository = try makeRepository()
        try await repository.save(makeResult(bpm: 80, createdAt: date(1)))
        try await repository.save(makeResult(bpm: 90, createdAt: date(2)))
        try await repository.save(makeResult(songID: "twinkle", bpm: 100, createdAt: date(3)))

        let bpm = try await repository.lastPracticeBPM(forPattern: "foundation")

        XCTAssertEqual(bpm, 90)
    }

    func test_lastPracticeBPM_withNoPracticeSession_isNil() async throws {
        let repository = try makeRepository()
        try await repository.save(makeResult(songID: "twinkle", bpm: 100))

        let bpm = try await repository.lastPracticeBPM(forPattern: "foundation")

        XCTAssertNil(bpm)
    }
}
