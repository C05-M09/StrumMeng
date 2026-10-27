import XCTest
@testable import StrumMeng

final class StrumPatternTests: XCTestCase {
    func test_strokeCases_areCodable() throws {
        for stroke in Stroke.allCases {
            let encoded = try JSONEncoder().encode(stroke)
            let decoded = try JSONDecoder().decode(Stroke.self, from: encoded)
            XCTAssertEqual(stroke, decoded)
        }
    }

    func test_pattern_codableRoundTrip() throws {
        let pattern = StrumPattern(
            id: "test-pattern",
            name: "Test Pattern",
            strokes: [.down, .up, .rest],
            beatLabels: ["1", "&", "2"],
            beatsPerPattern: 4,
            suggestedOrder: 1,
            defaultBPM: 75
        )

        let data = try JSONEncoder().encode(pattern)
        let decoded = try JSONDecoder().decode(StrumPattern.self, from: data)

        XCTAssertEqual(pattern, decoded)
    }

    func test_patternCatalog_containsFivePatterns() {
        XCTAssertEqual(PatternCatalog.all.count, 5)
    }

    func test_patternCatalog_hasUniqueIDs() {
        let ids = PatternCatalog.all.map(\.id)
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count)
    }

    func test_patternCatalog_isSortedBySuggestedOrder() {
        let orders = PatternCatalog.all.map(\.suggestedOrder)
        XCTAssertEqual(orders, [1, 2, 3, 4, 5])
    }

    func test_patternCatalog_lookupByID() {
        XCTAssertEqual(PatternCatalog.pattern(forID: "foundation"), PatternCatalog.foundation)
        XCTAssertEqual(PatternCatalog.pattern(forID: "subdivision"), PatternCatalog.subdivision)
        XCTAssertEqual(PatternCatalog.pattern(forID: "syncopation"), PatternCatalog.syncopation)
        XCTAssertEqual(PatternCatalog.pattern(forID: "upbeat"), PatternCatalog.theUpbeat)
        XCTAssertEqual(PatternCatalog.pattern(forID: "dynamic"), PatternCatalog.dynamic)
        XCTAssertNil(PatternCatalog.pattern(forID: "non-existent"))
    }

    func test_patternCatalog_eachPatternHasMatchingStrokesAndBeatLabels() {
        for pattern in PatternCatalog.all {
            XCTAssertEqual(
                pattern.strokes.count,
                pattern.beatLabels.count,
                "Pattern \(pattern.id) strokes count should match beatLabels count"
            )
            XCTAssertFalse(pattern.strokes.isEmpty)
        }
    }

    func test_loopDuration_calculatesCorrectTime() {
        let pattern = PatternCatalog.foundation // 8 strokes = 4 beats
        XCTAssertEqual(pattern.loopDuration(at: 60), 4.0, accuracy: 0.001)
        XCTAssertEqual(pattern.loopDuration(at: 120), 2.0, accuracy: 0.001)
        XCTAssertEqual(pattern.loopDuration(at: 0), 0.0)
    }

    func test_sessionDuration_calculatesTenRepetitionsByDefault() {
        let pattern = PatternCatalog.foundation
        // At 60 BPM, 1 loop is 4s, 10 loops is 40s
        XCTAssertEqual(pattern.sessionDuration(at: 60), 40.0, accuracy: 0.001)
        // At 120 BPM, 1 loop is 2s, 10 loops is 20s
        XCTAssertEqual(pattern.sessionDuration(at: 120), 20.0, accuracy: 0.001)
    }

    func test_totalStrumSteps_calculatesTotalBeatsAcrossSession() {
        let pattern = PatternCatalog.foundation // 8 strokes
        XCTAssertEqual(pattern.totalStrumSteps(), 80)
        XCTAssertEqual(pattern.totalStrumSteps(repetitions: 5), 40)
    }
}
