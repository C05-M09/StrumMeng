import XCTest
@testable import StrumMeng

final class SessionResultBuilderTests: XCTestCase {
    private let id = UUID()
    private let date = Date(timeIntervalSince1970: 1_000)

    private func build(_ events: [BeatEvent]) -> SessionResult {
        SessionResultBuilder.build(id: id, patternID: "foundation", bpm: 80, beatEvents: events, createdAt: date)
    }

    func test_counts_andAccuracy_matchTheBeats() {
        let result = build(PracticeFixtures.events([.perfect, .perfect, .perfect, .tooEarly, .miss, .miss]))
        XCTAssertEqual(result.perfectCount, 3)
        XCTAssertEqual(result.tooEarlyCount, 1)
        XCTAssertEqual(result.missCount, 2)
        XCTAssertEqual(result.accuracy, 0.5, accuracy: 1e-9)
    }

    func test_emptyBeatList_hasZeroAccuracyWithoutDividingByZero() {
        let result = build([])
        XCTAssertEqual(result.accuracy, 0)
        XCTAssertEqual(result.perfectCount + result.tooEarlyCount + result.missCount, 0)
    }

    func test_identity_isCarriedThrough_andItIsAPracticeSession() {
        let result = build([])
        XCTAssertEqual(result.id, id)
        XCTAssertEqual(result.patternID, "foundation")
        XCTAssertEqual(result.bpm, 80)
        XCTAssertEqual(result.createdAt, date)
        XCTAssertNil(result.songID)
    }

    func test_beatEvents_areStoredInStepOrderForReplay() {
        let events = [BeatEvent(stepIndex: 2, result: .miss, offsetMs: nil),
                      BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 3)]
        XCTAssertEqual(build(events).beatEvents.map(\.stepIndex), [0, 2])
    }
}
