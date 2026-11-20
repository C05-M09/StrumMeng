import XCTest
@testable import StrumMeng

final class SessionResultBuilderTests: XCTestCase {
    private let id = UUID()
    private let date = Date(timeIntervalSince1970: 1_000)

    private func build(_ events: [BeatEvent], strums: [RecordedStrum] = []) -> SessionResult {
        SessionResultBuilder.build(id: id, patternID: "foundation", bpm: 80, beatEvents: events,
                                   strums: strums, createdAt: date)
    }

    private func strum(at time: TimeInterval, extra: Bool) -> RecordedStrum {
        RecordedStrum(time: time, direction: .down, isExtra: extra)
    }

    func test_counts_andAccuracy_matchTheBeats_withHalfAPointForTooEarly() {
        let result = build(PracticeFixtures.events([.perfect, .perfect, .perfect, .tooEarly, .miss, .miss]))
        XCTAssertEqual(result.perfectCount, 3)
        XCTAssertEqual(result.tooEarlyCount, 1)
        XCTAssertEqual(result.missCount, 2)
        XCTAssertEqual(result.accuracy, 3.5 / 6, accuracy: 1e-9)
    }

    func test_allTooEarly_isHalfAccuracy() {
        XCTAssertEqual(build(PracticeFixtures.events([.tooEarly, .tooEarly])).accuracy, 0.5, accuracy: 1e-9)
    }

    func test_extraStrums_countAsMiss_andRaiseTheDivider() {
        // 60 nodes all Perfect, plus 10 swipes on rests: 60 / 70.
        let events = PracticeFixtures.events(Array(repeating: .perfect, count: 60))
        let strums = (0..<60).map { strum(at: Double($0), extra: false) }
            + (0..<10).map { strum(at: Double($0) + 0.5, extra: true) }
        let result = build(events, strums: strums)
        XCTAssertEqual(result.missCount, 10)
        XCTAssertEqual(result.extraStrumCount, 10)
        XCTAssertEqual(result.accuracy, 60.0 / 70.0, accuracy: 1e-9)
    }

    func test_strumsThatJudgedANode_doNotChangeTheScore() {
        let result = build(PracticeFixtures.events([.perfect, .miss]), strums: [strum(at: 0, extra: false)])
        XCTAssertEqual(result.missCount, 1)
        XCTAssertEqual(result.accuracy, 0.5, accuracy: 1e-9)
    }

    func test_strums_areStoredInTimeOrder() {
        let result = build([], strums: [strum(at: 1, extra: true), strum(at: -0.5, extra: false)])
        XCTAssertEqual(result.strums.map(\.time), [-0.5, 1])
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

    func test_showtimeSession_storesProvidedSongID() {
        let result = SessionResultBuilder.build(
            id: id,
            patternID: "foundation",
            songID: "twinkle",
            bpm: 80,
            beatEvents: [],
            strums: [],
            createdAt: date
        )
        XCTAssertEqual(result.songID, "twinkle")
    }

    func test_practiceSession_explicitNilSongID_storesNil() {
        let result = SessionResultBuilder.build(
            id: id,
            patternID: "foundation",
            songID: nil,
            bpm: 80,
            beatEvents: [],
            strums: [],
            createdAt: date
        )
        XCTAssertNil(result.songID)
    }

    func test_beatEvents_areStoredInStepOrderForReplay() {
        let events = [BeatEvent(stepIndex: 2, result: .miss, offsetMs: nil),
                      BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 3)]
        XCTAssertEqual(build(events).beatEvents.map(\.stepIndex), [0, 2])
    }
}
