import XCTest
@testable import StrumMeng

final class PatternListReducerTests: XCTestCase {
    func test_selectPattern_changesSelectionAndResetsTempoToDefault() throws {
        var state = makeLoadedState(selectedPatternID: "foundation", selectedBPM: 95)

        state = reduce(state, .selectPattern(id: "subdivision"))

        XCTAssertEqual(state.selectedPatternID, "subdivision")
        XCTAssertEqual(state.selectedBPM, 80)
    }

    func test_increaseBPM_addsFiveAndStopsAt120() {
        var state = makeLoadedState(selectedPatternID: "foundation", selectedBPM: 115)

        state = reduce(state, .increaseBPM)
        XCTAssertEqual(state.selectedBPM, 120)

        state = reduce(state, .increaseBPM)
        XCTAssertEqual(state.selectedBPM, 120)
    }

    func test_decreaseBPM_subtractsFiveAndStopsAt60() {
        var state = makeLoadedState(selectedPatternID: "foundation", selectedBPM: 65)

        state = reduce(state, .decreaseBPM)
        XCTAssertEqual(state.selectedBPM, 60)

        state = reduce(state, .decreaseBPM)
        XCTAssertEqual(state.selectedBPM, 60)
    }

    func test_setBPM_replacesTheTempoAndKeepsThePattern() {
        var state = makeLoadedState(selectedPatternID: "subdivision", selectedBPM: 80)

        state = reduce(state, .setBPM(70))

        XCTAssertEqual(state.selectedPatternID, "subdivision")
        XCTAssertEqual(state.selectedBPM, 70)
    }

    func test_setBPM_isClampedToThePracticeRange() {
        var state = makeLoadedState(selectedPatternID: "foundation", selectedBPM: 80)

        state = reduce(state, .setBPM(30))
        XCTAssertEqual(state.selectedBPM, PracticeTempoConfig.minimumBPM)

        state = reduce(state, .setBPM(200))
        XCTAssertEqual(state.selectedBPM, PracticeTempoConfig.maximumBPM)
    }

    func test_setBPM_onAnEmptyList_isIgnored() {
        XCTAssertEqual(reduce(.empty, .setBPM(70)), .empty)
    }

    func test_selectEveryPattern_isAllowed() {
        var state = makeLoadedState(selectedPatternID: "foundation", selectedBPM: 80)

        for pattern in PatternCatalog.all {
            state = reduce(state, .selectPattern(id: pattern.id))
            XCTAssertEqual(state.selectedPatternID, pattern.id)
        }
    }

    func test_unknownPattern_isIgnored() {
        let state = makeLoadedState(selectedPatternID: "foundation", selectedBPM: 80)

        XCTAssertEqual(reduce(state, .selectPattern(id: "unknown")), state)
    }

    private func makeLoadedState(
        selectedPatternID: String,
        selectedBPM: Int
    ) -> PatternListState {
        .loaded(
            patterns: PatternCatalog.all,
            selectedPatternID: selectedPatternID,
            selectedBPM: selectedBPM
        )
    }
}
