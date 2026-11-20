import XCTest
@testable import StrumMeng

@MainActor
final class FirstPlayInstructionsTests: XCTestCase {
    func test_emptyHistoryShowsInstructionsAndNextNavigatesOnlyOnce() async {
        let store = InMemoryPracticeGuidanceStore(hasCompletedGuidance: false)
        let player = InstructionPlayer()
        var starts = 0
        let model = makeModel(player: player, guidanceStore: store, ready: { starts += 1 })
        defer { model.stop() }

        // 1. First play shows instructions
        model.send(.next)
        XCTAssertEqual(model.state, .instructions(step: 0))
        XCTAssertEqual(starts, 0)
        XCTAssertFalse(store.hasCompletedGuidance)
        XCTAssertEqual(player.starts, 0)

        // 2. Next on instructions marks guidance complete, starts playback, and goes to listening
        model.send(.instructionsNext)
        model.send(.instructionsNext)
        XCTAssertEqual(model.state, .listening(step: 0, completed: false))
        XCTAssertTrue(store.hasCompletedGuidance)
        XCTAssertEqual(player.starts, 1)

        // 3. Completing loop and tapping ready stops playback and navigates only once
        player.elapsed = 3
        model.refreshProgress()
        XCTAssertTrue(model.state.canProceed)

        model.send(.ready)
        model.send(.ready)
        XCTAssertTrue(player.stopped)
        XCTAssertEqual(starts, 1)
        XCTAssertEqual(model.state, .departed)
    }

    func test_existingRecordSkipsInstructions() async {
        let store = InMemoryPracticeGuidanceStore(hasCompletedGuidance: true)
        let player = InstructionPlayer()
        var starts = 0
        let model = makeModel(player: player, guidanceStore: store, ready: { starts += 1 })
        defer { model.stop() }

        model.send(.next)
        XCTAssertEqual(model.state, .listening(step: 0, completed: false))
        XCTAssertEqual(player.starts, 1)

        player.elapsed = 3
        model.refreshProgress()
        XCTAssertTrue(model.state.canProceed)

        model.send(.ready)
        XCTAssertTrue(player.stopped)
        XCTAssertEqual(starts, 1)
        XCTAssertEqual(model.state, .departed)
    }

    func test_readyBeforeACompleteLoop_doesNotGoOn_andHistoryIsAskedOnlyOnceEarly() async {
        let history = TestHistory(hasRecords: false)
        let store = InMemoryPracticeGuidanceStore(hasCompletedGuidance: true)
        let model = makeModel(player: InstructionPlayer(), guidanceStore: store, history: history)
        defer { model.stop() }

        model.send(.next)
        model.send(.ready)
        for _ in 0..<100 { await Task.yield() }
        // Asked once when the example started; Ready before a full loop asks nothing more.
        let calls = await history.calls
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(model.state, .listening(step: 0, completed: false))
    }

    func test_backFromInstructions_stopsAndNavigatesBack() async {
        let store = InMemoryPracticeGuidanceStore(hasCompletedGuidance: false)
        let player = InstructionPlayer()
        var starts = 0
        var backs = 0
        let model = ListenViewModel(
            pattern: PatternCatalog.subdivision,
            bpm: 80,
            player: player,
            guidanceStore: store,
            onReady: { starts += 1 },
            onBack: { backs += 1 }
        )
        defer { model.stop() }

        model.send(.next)
        XCTAssertEqual(model.state, .instructions(step: 0))

        model.send(.back)
        XCTAssertEqual(backs, 1)
        XCTAssertEqual(starts, 0)
        XCTAssertEqual(model.state, .departed)
    }

    func test_instructionsPersistCompletionAcrossSessions() async {
        let store = InMemoryPracticeGuidanceStore(hasCompletedGuidance: false)
        let player = InstructionPlayer()
        let model1 = makeModel(player: player, guidanceStore: store)
        defer { model1.stop() }

        model1.send(.next)
        XCTAssertEqual(model1.state, .instructions(step: 0))
        model1.send(.instructionsNext)
        XCTAssertTrue(store.hasCompletedGuidance)

        let model2 = makeModel(player: player, guidanceStore: store)
        defer { model2.stop() }

        model2.send(.next)
        XCTAssertEqual(model2.state, .listening(step: 0, completed: false))
    }

    func test_reducerIgnoresStaleHistoryAndPrematureNext() {
        XCTAssertEqual(reduce(ListenState.information, .instructionsNext), .information)
        XCTAssertEqual(reduce(ListenState.departed, .historyChecked(hasRecords: false)), .departed)
        XCTAssertEqual(reduce(ListenState.instructions(step: 4), .progress(step: 5, completed: true)), .instructions(step: 4))
        XCTAssertEqual(reduce(ListenState.information, .showGuidance), .instructions(step: 0))
        XCTAssertEqual(reduce(ListenState.instructions(step: 0), .instructionsNext), .listening(step: 0, completed: false))
    }

    private func makeModel(
        player: InstructionPlayer,
        guidanceStore: (any PracticeGuidanceStore)? = nil,
        history: (any SessionHistoryChecking)? = nil,
        ready: @escaping () -> Void = {}
    ) -> ListenViewModel {
        ListenViewModel(
            pattern: PatternCatalog.subdivision,
            bpm: 80,
            player: player,
            history: history,
            guidanceStore: guidanceStore ?? InMemoryPracticeGuidanceStore(hasCompletedGuidance: false),
            onReady: ready,
            onBack: {}
        )
    }
}

private actor TestHistory: SessionHistoryChecking {
    let hasRecords: Bool
    var fails: Bool
    private(set) var calls = 0
    init(hasRecords: Bool, fails: Bool = false) { self.hasRecords = hasRecords; self.fails = fails }
    func allowSuccess() { fails = false }
    func hasSavedSessions() async throws -> Bool {
        calls += 1
        if fails { throw NSError(domain: "TestHistory", code: 1) }
        return hasRecords
    }
}

@MainActor
private final class InstructionPlayer: ListenPatternPlayer {
    var elapsed: TimeInterval = 0
    var stopped = false
    var starts = 0
    func start(pattern: StrumPattern, bpm: Int) throws { starts += 1; elapsed = 0 }
    func pause() {}
    func resume() {}
    func stop() { stopped = true }
}
