import XCTest
@testable import StrumMeng

@MainActor
final class FirstPlayInstructionsTests: XCTestCase {
    func test_emptyHistoryShowsInstructionsAndNextNavigatesOnlyOnce() async {
        let history = TestHistory(hasRecords: false)
        let player = InstructionPlayer()
        var starts = 0
        let model = makeModel(player: player, history: history, ready: { starts += 1 })
        defer { model.stop() }
        finishPreview(model, player)
        model.send(.ready)
        model.send(.ready)
        XCTAssertTrue(player.stopped)
        XCTAssertEqual(model.state, .checkingHistory(step: 0))
        await waitUntil { model.state == .instructions(step: 0) }
        XCTAssertEqual(model.state, .instructions(step: 0))
        XCTAssertEqual(starts, 0)
        let calls = await history.calls
        XCTAssertEqual(calls, 1)
        model.send(.instructionsNext)
        model.send(.instructionsNext)
        XCTAssertEqual(starts, 1)
        XCTAssertEqual(model.state, .departed)
    }

    func test_existingRecordSkipsInstructions() async {
        let player = InstructionPlayer()
        var starts = 0
        let model = makeModel(player: player, history: TestHistory(hasRecords: true), ready: { starts += 1 })
        defer { model.stop() }
        finishPreview(model, player)
        model.send(.ready)
        await waitUntil { model.state == .departed }
        XCTAssertEqual(starts, 1)
        XCTAssertEqual(model.state, .departed)
    }

    func test_readyBeforeACompleteLoopDoesNotQueryHistory() async {
        let history = TestHistory(hasRecords: false)
        let model = makeModel(player: InstructionPlayer(), history: history)
        defer { model.stop() }
        model.send(.next)
        model.send(.ready)
        await Task.yield()
        let calls = await history.calls
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(model.state, .listening(step: 0, completed: false))
    }

    func test_historyFailureCanRetryWithoutStartingPlayOrRestartingAudio() async {
        let history = TestHistory(hasRecords: false, fails: true)
        let player = InstructionPlayer()
        var starts = 0
        let model = makeModel(player: player, history: history, ready: { starts += 1 })
        defer { model.stop() }
        finishPreview(model, player)
        model.send(.ready)
        await waitUntil { if case .historyFailed = model.state { return true }; return false }
        guard case .historyFailed = model.state else { return XCTFail("Expected history error") }
        XCTAssertEqual(starts, 0)
        await history.allowSuccess()
        model.send(.retryHistory)
        await waitUntil { model.state == .instructions(step: 0) }
        XCTAssertEqual(model.state, .instructions(step: 0))
        XCTAssertEqual(player.starts, 1)
    }

    func test_backIgnoresAnInFlightHistoryResult() async {
        let history = DelayedHistory()
        let player = InstructionPlayer()
        var starts = 0
        var backs = 0
        let model = ListenViewModel(pattern: PatternCatalog.subdivision, bpm: 80,
            player: player, history: history, onReady: { starts += 1 }, onBack: { backs += 1 })
        defer { model.stop() }
        finishPreview(model, player)
        model.send(.ready)
        for _ in 0..<1000 { if await history.started { break }; await Task.yield() }
        model.send(.back)
        await history.finish()
        for _ in 0..<20 { await Task.yield() }
        XCTAssertEqual(backs, 1)
        XCTAssertEqual(starts, 0)
        XCTAssertEqual(model.state, .departed)
    }

    func test_reducerIgnoresStaleHistoryAndPrematureNext() {
        XCTAssertEqual(reduce(ListenState.information, .instructionsNext), .information)
        XCTAssertEqual(reduce(ListenState.departed, .historyChecked(hasRecords: false)), .departed)
        XCTAssertEqual(reduce(ListenState.instructions(step: 4), .progress(step: 5, completed: true)), .instructions(step: 4))
    }

    private func finishPreview(_ model: ListenViewModel, _ player: InstructionPlayer) {
        model.send(.next)
        player.elapsed = 3
        model.refreshProgress()
    }

    private func makeModel(player: InstructionPlayer, history: any SessionHistoryChecking,
                           ready: @escaping () -> Void = {}) -> ListenViewModel {
        ListenViewModel(pattern: PatternCatalog.subdivision, bpm: 80, player: player,
                        history: history, onReady: ready, onBack: {})
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1000 where !condition() { await Task.yield() }
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

private actor DelayedHistory: SessionHistoryChecking {
    private(set) var started = false
    private var continuation: CheckedContinuation<Bool, Never>?
    func hasSavedSessions() async throws -> Bool {
        started = true
        return await withCheckedContinuation { continuation = $0 }
    }
    func finish() { continuation?.resume(returning: true); continuation = nil }
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
