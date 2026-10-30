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

    func test_selectingPattern_usesItsOwnRecordsWithoutChangingTempoRules() async {
        let repository = MockSessionRepository()
        let records = Dictionary(uniqueKeysWithValues: PatternCatalog.all.map {
            ($0.id, RecordsViewModel(patternID: $0.id, repository: repository))
        })
        let viewModel = PatternListViewModel(
            recordsViewModels: records,
            onListenRequested: { _, _ in },
            onBackRequested: {}
        )

        for pattern in PatternCatalog.all {
            viewModel.send(.selectPattern(id: pattern.id))
            viewModel.send(.increaseBPM)
            let selectedID = viewModel.state.selectedPatternID ?? ""
            await viewModel.recordsViewModels[selectedID]?.load()
        }

        let calls = await repository.topRecordsCalls
        XCTAssertEqual(calls.map(\.patternID), PatternCatalog.all.map(\.id))
        XCTAssertTrue(calls.allSatisfy { $0.limit == nil && $0.sortedBy == .accuracy })
        XCTAssertEqual(viewModel.state.selectedBPM, 85)
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
