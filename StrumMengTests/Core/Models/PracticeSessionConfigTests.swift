import XCTest
@testable import StrumMeng

final class PracticeSessionConfigTests: XCTestCase {
    private let pattern = PatternCatalog.all[0]

    func test_duration_repeatsPatternTenTimes() {
        XCTAssertEqual(PracticeSessionConfig.patternRepetitions, 10)
        XCTAssertEqual(
            PracticeSessionConfig.durationSeconds(for: pattern, bpm: 80),
            30,
            accuracy: 0.001
        )
    }

    func test_duration_changesWithBPM() {
        XCTAssertEqual(
            PracticeSessionConfig.durationSeconds(for: pattern, bpm: 60),
            40,
            accuracy: 0.001
        )
        XCTAssertEqual(
            PracticeSessionConfig.durationSeconds(for: pattern, bpm: 120),
            20,
            accuracy: 0.001
        )
    }

    func test_durationWithInvalidBPM_isZero() {
        XCTAssertEqual(
            PracticeSessionConfig.durationSeconds(for: pattern, bpm: 0),
            0
        )
    }

    func test_duration_usesDeclaredBeatsRatherThanNotationStepCount() {
        let threeBeatPattern = StrumPattern(
            id: "three-beats",
            name: "Three Beat Pattern",
            strokes: [.down, .rest, .down, .up, .rest, .up],
            beatLabels: ["1", "&", "2", "&", "3", "&"],
            beatsPerPattern: 3,
            suggestedOrder: 1,
            defaultBPM: 60
        )

        XCTAssertEqual(
            PracticeSessionConfig.durationSeconds(for: threeBeatPattern, bpm: 60),
            30,
            accuracy: 0.001
        )
        XCTAssertEqual(
            PracticeSessionConfig.durationSeconds(for: threeBeatPattern, bpm: 120),
            15,
            accuracy: 0.001
        )
    }

    func test_durationLabel_underOneMinute_usesSeconds() {
        XCTAssertEqual(
            PracticeSessionConfig.durationLabel(for: pattern, bpm: 80),
            "30 sec"
        )
    }

    func test_durationLabel_atOneMinute_usesMinutes() {
        XCTAssertEqual(
            PracticeSessionConfig.durationLabel(for: pattern, bpm: 40),
            "1 min"
        )
    }

    func test_durationLabel_overOneMinute_keepsRemainingSeconds() {
        XCTAssertEqual(
            PracticeSessionConfig.durationLabel(for: pattern, bpm: 30),
            "1 min 20 sec"
        )
    }
}
