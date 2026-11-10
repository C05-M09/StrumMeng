import XCTest
@testable import StrumMeng

/// Stands in for the repository's "last played tempo" in tests.
private final class BPMHistory {
    var values: [String: Int] = [:]
}

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

    func test_setBPM_doesNotNavigate_andTheNextPlayUsesIt() {
        var routedBPMs: [Int] = []
        let viewModel = PatternListViewModel(
            onListenRequested: { _, bpm in routedBPMs.append(bpm) },
            onBackRequested: {}
        )

        viewModel.send(.setBPM(70))
        XCTAssertEqual(routedBPMs, [], "Setting the tempo must not open Listen by itself")

        viewModel.send(.tapPlay)
        XCTAssertEqual(routedBPMs, [70])
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

    func test_reloadRecords_updatesEveryPatternsRecords() async {
        let repository = MockSessionRepository()
        let records = [
            "a": RecordsViewModel(patternID: "a", repository: repository),
            "b": RecordsViewModel(patternID: "b", repository: repository)
        ]
        let sut = PatternListViewModel(
            recordsViewModels: records,
            onListenRequested: { _, _ in },
            onBackRequested: {}
        )
        let result = SessionResult(
            id: UUID(), patternID: "a", songID: nil, bpm: 100, accuracy: 0.9,
            perfectCount: 0, tooEarlyCount: 0, missCount: 0,
            createdAt: Date(timeIntervalSince1970: 0), beatEvents: []
        )
        await repository.stub(records: [result], lastBPM: nil)

        await sut.reloadRecords()

        for viewModel in records.values {
            guard case .loaded(let rows) = viewModel.state else {
                return XCTFail("State seharusnya .loaded, tapi \(viewModel.state)")
            }
            XCTAssertEqual(rows.count, 1)
        }
    }

    func test_reloadRecords_changesRefreshID() async {
        let sut = PatternListViewModel(onListenRequested: { _, _ in }, onBackRequested: {})
        let before = sut.recordsRefreshID

        await sut.reloadRecords()

        XCTAssertEqual(sut.recordsRefreshID, before + 1, "Token harus berubah supaya Records dibangun ulang")
    }

    // MARK: - Last played tempo

    func test_loadRememberedBPMs_appliesToTheSelectedPattern() async {
        let history = BPMHistory()
        let sut = makeViewModel(remembering: history)
        history.values[sut.state.patterns[0].id] = 95

        await sut.loadRememberedBPMs()

        XCTAssertEqual(sut.state.selectedBPM, 95)
    }

    func test_selectPattern_neverPlayed_usesDefaultBPM() async {
        let sut = makeViewModel(remembering: BPMHistory())
        await sut.loadRememberedBPMs()
        let second = sut.state.patterns[1]

        sut.send(.selectPattern(id: second.id))

        XCTAssertEqual(sut.state.selectedBPM, PracticeTempoConfig.clamped(second.defaultBPM))
    }

    func test_selectPattern_alreadyPlayed_usesLastPlayedBPM() async {
        let history = BPMHistory()
        let sut = makeViewModel(remembering: history)
        let second = sut.state.patterns[1]
        history.values[second.id] = 105
        await sut.loadRememberedBPMs()

        sut.send(.selectPattern(id: second.id))

        XCTAssertEqual(sut.state.selectedBPM, 105)
    }

    func test_selectPattern_dropsAnUnplayedManualChange() async {
        let history = BPMHistory()
        let sut = makeViewModel(remembering: history)
        let first = sut.state.patterns[0].id
        let second = sut.state.patterns[1].id
        history.values[first] = 90
        await sut.loadRememberedBPMs()
        sut.send(.increaseBPM)                      // 95, never played

        sut.send(.selectPattern(id: second))
        sut.send(.selectPattern(id: first))

        XCTAssertEqual(sut.state.selectedBPM, 90)
    }

    func test_reloadRecords_updatesMemoryButKeepsTheTempoOnScreen() async {
        let history = BPMHistory()
        let sut = makeViewModel(remembering: history)
        let first = sut.state.patterns[0].id
        let second = sut.state.patterns[1].id
        sut.send(.setBPM(90))                       // Retry chose 90
        history.values[first] = 80                  // the session that just ended was played at 80

        await sut.reloadRecords()

        XCTAssertEqual(sut.state.selectedBPM, 90, "Tempo di layar tidak boleh berubah")
        sut.send(.selectPattern(id: second))
        sut.send(.selectPattern(id: first))
        XCTAssertEqual(sut.state.selectedBPM, 80, "BPM terakhir yang dimainkan sudah tercatat")
    }

    private func makeViewModel<S: Sequence>(patterns: S) -> PatternListViewModel
    where S.Element == StrumPattern {
        PatternListViewModel(
            patterns: Array(patterns),
            onListenRequested: { _, _ in },
            onBackRequested: {}
        )
    }

    private func makeViewModel(remembering history: BPMHistory) -> PatternListViewModel {
        PatternListViewModel(
            lastPlayedBPM: { history.values[$0] },
            onListenRequested: { _, _ in },
            onBackRequested: {}
        )
    }
}
