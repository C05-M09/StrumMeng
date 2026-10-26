import XCTest
@testable import StrumMeng

@MainActor
final class PatternListViewModelTests: XCTestCase {
    func test_init_ordersPatternsAndSelectsFoundation() {
        let viewModel = makeViewModel(patterns: PatternCatalog.all.reversed())

        XCTAssertEqual(viewModel.state.patterns.map(\.suggestedOrder), [1, 2, 3, 4, 5])
        XCTAssertEqual(viewModel.state.selectedPatternID, "foundation")
        XCTAssertEqual(viewModel.state.selectedBPM, 80)
    }

    func test_tapPlay_routesSelectedPatternAndTempoToListen() {
        var routedPatternID: String?
        var routedBPM: Int?
        let viewModel = PatternListViewModel(
            onListenRequested: { patternID, bpm in
                routedPatternID = patternID
                routedBPM = bpm
            },
            onBackRequested: {}
        )

        viewModel.send(.selectPattern(id: "dynamic"))
        viewModel.send(.increaseBPM)
        viewModel.send(.tapPlay)

        XCTAssertEqual(routedPatternID, "dynamic")
        XCTAssertEqual(routedBPM, 85)
    }

    func test_tapBack_requestsRouterPop() {
        var didRequestBack = false
        let viewModel = PatternListViewModel(
            onListenRequested: { _, _ in },
            onBackRequested: { didRequestBack = true }
        )

        viewModel.send(.tapBack)

        XCTAssertTrue(didRequestBack)
    }

    private func makeViewModel<S: Sequence>(patterns: S) -> PatternListViewModel
    where S.Element == StrumPattern {
        PatternListViewModel(
            patterns: Array(patterns),
            onListenRequested: { _, _ in },
            onBackRequested: {}
        )
    }
}
