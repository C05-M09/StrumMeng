import XCTest
@testable import StrumMeng

final class StrumPatternTests: XCTestCase {
    func test_strokeCases_areCodable() throws {
        let strokes: [Stroke] = [.down, .up, .rest]
        for stroke in strokes {
            let encoded = try JSONEncoder().encode(stroke)
            let decoded = try JSONDecoder().decode(Stroke.self, from: encoded)
            XCTAssertEqual(stroke, decoded)
        }
    }

    func test_pattern_codableRoundTrip() throws {
        let pattern = StrumPattern(
            id: "test-pattern",
            name: "Test Pattern",
            strokes: [.down, .up, .rest, .down],
            beatLabels: ["1", "&", "2", "&"],
            beatsPerPattern: 2,
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

    func test_patternCatalog_usesStableIDs() {
        XCTAssertEqual(
            PatternCatalog.all.map(\.id),
            ["foundation", "subdivision", "syncopation", "upbeat", "dynamic"]
        )
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

}
