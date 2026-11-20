import XCTest
@testable import StrumMeng

final class SessionRecordMapperTests: XCTestCase {
    private func makeResult(beatEvents: [BeatEvent], strums: [RecordedStrum] = []) -> SessionResult {
        SessionResult(
            id: UUID(),
            patternID: "foundation",
            songID: nil,
            bpm: 80,
            accuracy: 0.75,
            perfectCount: 6,
            tooEarlyCount: 1,
            missCount: 1,
            createdAt: Date(timeIntervalSince1970: 1_000),
            beatEvents: beatEvents,
            strums: strums
        )
    }

    func test_roundTrip_keepsEveryBeatEventIncludingMissingOffset() throws {
        let events = [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: -12.5),
            BeatEvent(stepIndex: 1, result: .tooEarly, offsetMs: -90),
            BeatEvent(stepIndex: 2, result: .miss, offsetMs: nil)
        ]
        let original = makeResult(beatEvents: events)

        let record = try SessionRecordMapper.makeRecord(from: original)
        let restored = try SessionRecordMapper.makeResult(from: record)

        XCTAssertEqual(restored, original)
    }

    func test_roundTrip_withNoBeatEvents_returnsAnEmptyList() throws {
        let original = makeResult(beatEvents: [])

        let record = try SessionRecordMapper.makeRecord(from: original)
        let restored = try SessionRecordMapper.makeResult(from: record)

        XCTAssertEqual(restored.beatEvents, [])
    }

    func test_roundTrip_keepsEveryStrumIncludingExtraOnes() throws {
        let strums = [
            RecordedStrum(time: -0.4, direction: .down, isExtra: false),
            RecordedStrum(time: 0.01, direction: .down, isExtra: false),
            RecordedStrum(time: 0.375, direction: .up, isExtra: true)
        ]
        let original = makeResult(beatEvents: [BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 10)],
                                  strums: strums)

        let record = try SessionRecordMapper.makeRecord(from: original)
        let restored = try SessionRecordMapper.makeResult(from: record)

        XCTAssertEqual(restored.strums, strums)
        XCTAssertEqual(restored.extraStrumCount, 1)
    }

    func test_recordSavedBeforeStrumsWereRecorded_hasNoStrums() throws {
        let record = PracticeSessionRecord(
            id: UUID(),
            patternID: "foundation",
            songID: nil,
            bpm: 80,
            accuracy: 0.5,
            perfectCount: 1,
            tooEarlyCount: 0,
            missCount: 1,
            createdAt: Date(timeIntervalSince1970: 0),
            beatEventsData: Data("[]".utf8),
            strumsData: nil
        )

        XCTAssertEqual(try SessionRecordMapper.makeResult(from: record).strums, [])
    }

    func test_makeResult_withCorruptData_throwsDecodingFailed() {
        let id = UUID()
        let record = PracticeSessionRecord(
            id: id,
            patternID: "foundation",
            songID: nil,
            bpm: 80,
            accuracy: 0.5,
            perfectCount: 0,
            tooEarlyCount: 0,
            missCount: 0,
            createdAt: Date(timeIntervalSince1970: 0),
            beatEventsData: Data("not json".utf8)
        )

        XCTAssertThrowsError(try SessionRecordMapper.makeResult(from: record)) { error in
            XCTAssertEqual(error as? SessionRepositoryError, .decodingFailed(recordID: id))
        }
    }
}
