import XCTest
@testable import StrumMeng

final class PatternCatalogTests: XCTestCase {
    func test_allPatterns_areInSuggestedOrderAndUnlocked() {
        XCTAssertEqual(PatternCatalog.all.count, 5)
        XCTAssertEqual(PatternCatalog.all.map(\.suggestedOrder), [1, 2, 3, 4, 5])
        XCTAssertEqual(
            PatternCatalog.all.map(\.name),
            [
                "Foundation Strum",
                "Subdivision Strum",
                "Syncopation Strum",
                "The Upbeat Strum",
                "Dynamic Strum",
            ]
        )
    }

    func test_allPatterns_haveEightNotationStepsAndDefaultTempo() {
        for pattern in PatternCatalog.all {
            XCTAssertEqual(pattern.strokes.count, 8)
            XCTAssertEqual(pattern.beatLabels, ["1", "&", "2", "&", "3", "&", "4", "&"])
            XCTAssertEqual(pattern.beatsPerPattern, 4)
            XCTAssertEqual(pattern.defaultBPM, 80)
        }
    }
}
