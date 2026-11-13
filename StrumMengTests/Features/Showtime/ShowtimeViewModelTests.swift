import XCTest
import Observation
@testable import StrumMeng

@MainActor
final class ShowtimeViewModelTests: XCTestCase {
    private func make(connected: Bool = true, songIndex: Int = 0) -> (ShowtimeViewModel, FakeSongDemoPlayer, FakeSongGameplay) {
        let demo = FakeSongDemoPlayer()
        let game = FakeSongGameplay()
        game.isControllerConnected = connected
        let model = ShowtimeViewModel(song: DummySongCatalog().songs[songIndex], demo: demo, gameplay: game,
                                      repository: MockSessionRepository(), onBack: {})
        model.appear()
        return (model, demo, game)
    }
    /// Await delivery rather than guessing how many scheduler yields the event stream needs.
    private func deliver(_ event: SongDemoEvent, to demo: FakeSongDemoPlayer,
                         observing model: ShowtimeViewModel) async {
        let changed = expectation(description: "Preview event delivered")
        withObservationTracking {
            _ = model.state
            _ = model.previewStep
            _ = model.completedPatternIndices
        } onChange: {
            changed.fulfill()
        }
        demo.emit(event)
        await fulfillment(of: [changed], timeout: 2)
    }

    func test_introNextStartsDemoAndEarlyReadyDoesNotStartGame() async {
        let (model, demo, game) = make()
        await model.send(.ready)
        XCTAssertEqual(model.state, .intro)
        await model.send(.next)
        XCTAssertEqual(demo.starts, 1)
        await model.send(.ready)
        XCTAssertEqual(model.state, .listening(0))
        XCTAssertEqual(game.readyCalls, 0)
        await model.disappear()
    }
    func test_demoEventsUnlockReadyOnlyOnFinishedAndThenStopBeforeGame() async {
        let (model, demo, game) = make()
        await model.send(.next)
        await deliver(.step(7), to: demo, observing: model)
        XCTAssertFalse(model.canReady)
        await deliver(.finished, to: demo, observing: model)
        XCTAssertTrue(model.canReady)
        await model.send(.ready)
        XCTAssertEqual(demo.stops, 1)
        XCTAssertEqual(game.readyCalls, 1)
        XCTAssertEqual(model.state, .countIn(3))
        await model.disappear()
    }
    func test_pauseAndResumePreviewDoNotResetIt() async {
        let (model, demo, game) = make()
        await model.send(.next)
        await model.send(.previewStep(5))
        await model.send(.pause(.user))
        XCTAssertEqual(model.state, .paused(.listening(5), .user))
        XCTAssertEqual(demo.pauses, 1)
        await model.send(.resume)
        XCTAssertEqual(model.state, .listening(5))
        XCTAssertEqual(demo.resumes, 1)
        XCTAssertEqual(game.readyCalls, 0)
        await model.disappear()
    }
    func test_disconnectedReadyWaitsForReconnectBeforeStartingCountIn() async {
        let (model, demo, game) = make(connected: false)
        await model.send(.next); await model.send(.previewFinished)
        await model.send(.ready)
        XCTAssertEqual(model.state, .paused(.ready, .connection))
        XCTAssertEqual(demo.pauses, 1)
        XCTAssertFalse(demo.isPlaying)
        await model.send(.resume)
        XCTAssertEqual(model.state, .paused(.ready, .connection))
        game.isControllerConnected = true
        game.onConnectionChanged?(true)
        await model.send(.resume)
        XCTAssertEqual(model.state, .ready)
        await model.send(.ready)
        XCTAssertEqual(game.readyCalls, 1)
        await model.disappear()
    }
    func test_gameplayCallbacksDrivePauseAndFinishWithoutUI() async {
        let (model, _, game) = make()
        await model.send(.next); await model.send(.previewFinished); await model.send(.ready)
        game.change(.countIn(2)); XCTAssertEqual(model.state, .countIn(2))
        game.change(.playing); XCTAssertEqual(model.state, .playing)
        game.change(.disconnected)
        XCTAssertEqual(model.state, .paused(.playing, .connection))
        await model.send(.resume)
        game.change(.playing)
        let result = SessionResult(id: UUID(), patternID: "foundation", songID: "dummy-twinkle", bpm: 80,
            accuracy: 1, perfectCount: 1, tooEarlyCount: 0, missCount: 0,
            createdAt: Date(timeIntervalSince1970: 0), beatEvents: PracticeFixtures.events([.perfect]))
        game.change(.finished(result))
        guard case .finished(let finished) = model.state else { return XCTFail("Expected finished") }
        XCTAssertEqual(finished.songID, "dummy-twinkle")
        XCTAssertEqual(finished, result, "The coordinator must forward the builder result unchanged")
        await model.send(.restart)
        XCTAssertEqual(model.state, .listening(0))
        await model.disappear()
    }

    func test_finishedSession_keepsTheLaneMovingThroughTheEndBreak_thenShowsResults() async {
        let (model, _, game) = make()
        await model.send(.next); await model.send(.previewFinished); await model.send(.ready)
        game.change(.playing)
        let result = SessionResult(id: UUID(), patternID: "foundation", songID: "dummy-twinkle", bpm: 80,
            accuracy: 1, perfectCount: 1, tooEarlyCount: 0, missCount: 0,
            createdAt: Date(timeIntervalSince1970: 0), beatEvents: PracticeFixtures.events([.perfect]))
        game.isAnimating = true    // the gameplay's 2 s break after the last node
        game.change(.finished(result))
        XCTAssertTrue(model.isWrappingUp)
        XCTAssertTrue(model.isAnimating)
        game.isAnimating = false
        XCTAssertFalse(model.isWrappingUp, "The results show once the break is over")
        XCTAssertFalse(model.isAnimating)
        await model.disappear()
    }

    func test_readyCallout_coversTheCountInAndTheLeadIn() async {
        let (model, _, game) = make()
        await model.send(.next); await model.send(.previewFinished); await model.send(.ready)
        game.change(.countIn(3))
        let slot = model.timeline.slotInterval
        game.frameLeadInSlots = 4
        game.frameSongTime = -10 * slot
        XCTAssertEqual(model.playFrame().phase, .ready)
        game.frameSongTime = -9 * slot
        XCTAssertNotEqual(model.playFrame().phase, .ready, "Counting in once the first tick played")
        await model.disappear()
    }

    /// A finished run on a song model with its summary, and the repository the summary saves to.
    private func makeFinished(onBack: @escaping () -> Void = {}) async
        -> (ShowtimeViewModel, FakeSongGameplay, MockSessionRepository, SessionResult) {
        let repo = MockSessionRepository()
        let game = FakeSongGameplay()
        game.isControllerConnected = true
        let model = ShowtimeViewModel(song: DummySongCatalog().songs[0], demo: FakeSongDemoPlayer(),
                                      gameplay: game, repository: repo, onBack: onBack)
        model.appear()
        await model.send(.next)
        await model.send(.previewFinished)
        await model.send(.ready)
        game.change(.countIn(3))
        game.change(.playing)
        let result = SessionResult(id: UUID(), patternID: "foundation", songID: "dummy-twinkle", bpm: 80,
            accuracy: 1, perfectCount: 1, tooEarlyCount: 0, missCount: 0, createdAt: Date(),
            beatEvents: PracticeFixtures.events([.perfect]))
        game.change(.finished(result))
        return (model, game, repo, result)
    }

    private func waitForState(_ expected: ShowtimeState, of model: ShowtimeViewModel) async {
        for _ in 0..<100 where model.state != expected { await Task.yield() }
    }

    func test_gameplayFinish_opensSummaryWithResultAndSongInfo_withoutSavingYet() async {
        let (model, _, repo, result) = await makeFinished()
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(model.state, .finished(result))
        XCTAssertEqual(model.summary?.result, result)
        XCTAssertEqual(model.songInfo.title, DummySongCatalog().songs[0].title)
        XCTAssertEqual(model.songInfo.chords, DummySongCatalog().songs[0].distinctChords)
        let saved = await repo.savedResults
        XCTAssertTrue(saved.isEmpty, "Only the summary saves, when it first appears")
        await model.disappear()
    }

    func test_summaryAppearingTwice_savesTheRunOnce() async {
        let (model, _, repo, result) = await makeFinished()
        let summary = try? XCTUnwrap(model.summary)
        await summary?.onAppear()
        await summary?.onAppear()
        let saved = await repo.savedResults
        XCTAssertEqual(saved.map(\.id), [result.id])
        XCTAssertEqual(saved.first?.songID, "dummy-twinkle")
        await model.disappear()
    }

    func test_summaryRetry_savesThenReturnsToListenAndDropsSummary() async {
        let (model, game, repo, result) = await makeFinished()
        model.summary?.send(.tapRetry)
        await waitForState(.listening(0), of: model)
        XCTAssertEqual(model.state, .listening(0))
        XCTAssertNil(model.summary)
        XCTAssertEqual(game.restartCalls, 1)
        let saved = await repo.savedResults
        XCTAssertEqual(saved.map(\.id), [result.id])
        await model.disappear()
    }

    func test_summaryBackToMain_savesThenLeavesForTheSongList() async {
        var exits = 0
        let (model, _, repo, result) = await makeFinished(onBack: { exits += 1 })
        model.summary?.send(.tapBackToMain)
        await waitForState(.exited, of: model)
        XCTAssertEqual(model.state, .exited)
        XCTAssertEqual(exits, 1)
        XCTAssertNil(model.summary)
        let saved = await repo.savedResults
        XCTAssertEqual(saved.map(\.id), [result.id])
        await model.disappear()
    }

    func test_summaryReplay_staysOnTheFinishedRun() async {
        let (model, _, _, result) = await makeFinished()
        model.summary?.send(.tapReplay)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(model.state, .finished(result))
        XCTAssertNotNil(model.summary)
        await model.disappear()
    }

    func test_restartIgnoresCompletionFromPreviousPreview() async {
        let (model, demo, _) = make()
        await model.send(.next)
        let oldRun = demo.channel.continuation
        await model.send(.pause(.user))
        await model.send(.restart)
        oldRun.yield(.finished)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(model.state, .listening(0))
        XCTAssertFalse(model.canReady)
        await deliver(.finished, to: demo, observing: model)
        XCTAssertTrue(model.canReady)
        await model.disappear()
    }

    func test_readyRequiresAllDistinctPatternsAndSwitchingPreservesCompletedLoops() async {
        let (model, demo, game) = make(songIndex: 1)
        await model.send(.next)
        await deliver(.finished, to: demo, observing: model)
        XCTAssertFalse(model.canReady)
        XCTAssertEqual(model.completedPatternIndices, [0])
        await model.send(.previewFinished) // Repeating pattern 1 does not count as pattern 2.
        await model.send(.ready)
        XCTAssertEqual(game.readyCalls, 0)
        XCTAssertFalse(model.canReady)
        await model.send(.selectPattern(1))
        XCTAssertEqual(model.selectedPatternIndex, 1)
        XCTAssertEqual(model.state, .listening(0))
        XCTAssertEqual(demo.startedPatternIDs, ["subdivision", "foundation"])
        await deliver(.finished, to: demo, observing: model)
        XCTAssertTrue(model.canReady)
        XCTAssertEqual(model.completedPatternIndices, [0, 1])
        await model.send(.selectPattern(0))
        XCTAssertTrue(model.canReady, "Every required pattern was already heard once")
        await model.send(.ready)
        XCTAssertEqual(game.readyCalls, 1)
        await model.disappear()
    }
    func test_switchingBeforeFullLoopDoesNotCreditTheUnfinishedPattern() async {
        let (model, demo, _) = make(songIndex: 1)
        await model.send(.next)
        await deliver(.step(3), to: demo, observing: model)
        await model.send(.selectPattern(1))
        await deliver(.finished, to: demo, observing: model)
        XCTAssertEqual(model.completedPatternIndices, [1])
        XCTAssertFalse(model.canReady)
        await model.send(.selectPattern(0))
        await deliver(.finished, to: demo, observing: model)
        XCTAssertTrue(model.canReady)
        await model.disappear()
    }
    func test_pausePreservesHeardPatternsButRestartClearsThem() async {
        let (model, demo, _) = make(songIndex: 1)
        await model.send(.next)
        await deliver(.finished, to: demo, observing: model)
        await model.send(.pause(.user)); await model.send(.resume)
        XCTAssertEqual(model.completedPatternIndices, [0])
        await model.send(.selectPattern(1))
        await deliver(.finished, to: demo, observing: model)
        XCTAssertTrue(model.canReady)
        await model.send(.pause(.user)); await model.send(.restart)
        XCTAssertEqual(model.selectedPatternIndex, 0)
        XCTAssertTrue(model.completedPatternIndices.isEmpty)
        XCTAssertFalse(model.canReady)
        await model.send(.previewFinished)
        XCTAssertFalse(model.canReady)
        await model.disappear()
    }
    func test_connectionCallbackMutesPreviewAndRepeatedDisconnectStillKeepsItMuted() async {
        let (model, demo, game) = make()
        await model.send(.next)
        XCTAssertTrue(demo.isPlaying)
        let paused = expectation(description: "Disconnected pause")
        withObservationTracking { _ = model.state } onChange: { paused.fulfill() }
        game.isControllerConnected = false
        game.onConnectionChanged?(false)
        await fulfillment(of: [paused], timeout: 2)
        XCTAssertEqual(model.state, .paused(.listening(0), .connection))
        XCTAssertFalse(demo.isPlaying)
        XCTAssertGreaterThan(demo.pauses, 0)
        await model.send(.pause(.connection))
        XCTAssertFalse(demo.isPlaying)
        await model.disappear()
    }
    func test_readyStaysAvailableWhilePatternContinuesAndPauseResumesAudio() async {
        let (model, demo, _) = make()
        await model.send(.next)
        await deliver(.finished, to: demo, observing: model)
        await deliver(.step(2), to: demo, observing: model)
        XCTAssertTrue(model.canReady)
        XCTAssertEqual(model.previewStep, 2)
        await model.send(.pause(.user))
        await model.send(.resume)
        XCTAssertTrue(model.canReady)
        XCTAssertEqual(demo.resumes, 1)
        await model.disappear()
    }
    func test_invalidPatternSelectionAndSwitchingDuringGameAreIgnored() async {
        let (model, demo, _) = make(songIndex: 1)
        await model.send(.selectPattern(1))
        XCTAssertEqual(model.state, .intro)
        await model.send(.next)
        await model.send(.selectPattern(-1)); await model.send(.selectPattern(99))
        XCTAssertEqual(demo.starts, 1)
        await model.send(.previewFinished)
        await model.send(.selectPattern(1)); await model.send(.previewFinished)
        await model.send(.ready)
        await model.send(.selectPattern(0))
        XCTAssertEqual(model.selectedPatternIndex, 1)
        XCTAssertEqual(model.state, .countIn(3))
        await model.disappear()
    }

    func test_backCancelsSourcesExitsAndIgnoresStaleDemoEvents() async {
        let demo = FakeSongDemoPlayer(); let game = FakeSongGameplay(); var exits = 0
        let model = ShowtimeViewModel(song: DummySongCatalog().songs[0], demo: demo, gameplay: game,
                                     repository: MockSessionRepository(), onBack: { exits += 1 })
        model.appear(); await model.send(.next)
        await model.send(.back)
        demo.emit(.finished)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(model.state, .exited)
        XCTAssertEqual(exits, 1)
        XCTAssertGreaterThan(game.disappears, 0)
        await model.disappear()
    }
}

@MainActor
private final class FakeSongDemoPlayer: SongDemoPlayer {
    var channel = AsyncStream.makeStream(of: SongDemoEvent.self)
    var events: AsyncStream<SongDemoEvent> {
        channel = AsyncStream.makeStream(of: SongDemoEvent.self)
        return channel.stream
    }
    var elapsed: TimeInterval = 0
    var starts = 0; var stops = 0; var pauses = 0; var resumes = 0
    var isPlaying = false
    var startedPatternIDs: [String] = []
    func start(pattern: StrumPattern, bpm: Int) async {
        starts += 1
        isPlaying = true
        startedPatternIDs.append(pattern.id)
    }
    func stop() async { stops += 1; isPlaying = false }
    func pause() async { pauses += 1; isPlaying = false }
    func resume() async { resumes += 1; isPlaying = true }
    func emit(_ event: SongDemoEvent) { channel.continuation.yield(event) }
}

@MainActor
private final class FakeSongGameplay: SongGameplay {
    var state = PracticeState.ready
    var isControllerConnected = true
    var isAnimating = false
    var frameSongTime: TimeInterval = 0
    var frameLeadInSlots = 0
    var onStateChanged: ((PracticeState) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?
    var readyCalls = 0; var restartCalls = 0; var disappears = 0
    func onAppear() {}
    func onDisappear() async { disappears += 1 }
    func change(_ state: PracticeState) { self.state = state; onStateChanged?(state) }
    func send(_ event: PracticeEvent) async {
        if case .tapReady = event { readyCalls += 1 }
        if case .tapRestart = event { restartCalls += 1 }
        change(reduce(state, event))
    }
    func screenModel() -> PlayScreenModel {
        PlayScreenModel(title: "Song", bpm: 80, duration: 60, slotInterval: 0.375, songTime: frameSongTime,
                        phase: .playing, nodes: [], lastJudgement: nil, leadInSlots: frameLeadInSlots)
    }
}
