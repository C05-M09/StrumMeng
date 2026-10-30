import XCTest
@testable import StrumMeng

@MainActor
final class ListenTests: XCTestCase {
    func test_readyIsIgnoredUntilOneEntireLoopHasPlayed() {
        let player = FakeListenPlayer()
        var readyCount = 0
        let model = makeModel(player: player, onReady: { readyCount += 1 })
        model.send(.next)
        model.send(.ready)
        XCTAssertEqual(readyCount, 0)
        player.elapsed = 2.999
        model.refreshProgress()
        XCTAssertFalse(model.state.canProceed)
        player.elapsed = 3
        model.refreshProgress()
        XCTAssertTrue(model.state.canProceed)
        XCTAssertEqual(model.state.step, 0)
        model.send(.ready)
        XCTAssertEqual(readyCount, 1)
        XCTAssertTrue(player.stopped)
    }

    func test_resumePreservesProgressAndRestartRequiresANewLoop() {
        let player = FakeListenPlayer()
        let model = makeModel(player: player)
        model.send(.next)
        player.elapsed = 3.75
        model.refreshProgress()
        model.send(.pause)
        XCTAssertEqual(model.state, .paused(step: 2, completed: true))
        XCTAssertTrue(player.paused)
        model.send(.resume)
        XCTAssertTrue(model.state.canProceed)
        model.send(.pause)
        model.send(.restart)
        XCTAssertEqual(model.state, .listening(step: 0, completed: false))
        XCTAssertEqual(player.starts, 2)
        model.stop()
    }

    func test_audioFailureDoesNotUnlockReadyAndCanRetry() {
        let player = FakeListenPlayer()
        player.shouldFail = true
        let model = makeModel(player: player)
        model.send(.next)
        guard case .failed = model.state else { return XCTFail("Expected playback error") }
        XCTAssertFalse(model.state.canProceed)
        player.shouldFail = false
        model.send(.restart)
        XCTAssertEqual(model.state, .listening(step: 0, completed: false))
        model.stop()
    }

    func test_backStopsAudioAndRequestsMenu() {
        let player = FakeListenPlayer()
        var wentBack = false
        let model = ListenViewModel(pattern: PatternCatalog.all[0], bpm: 80, player: player,
                                    onReady: {}, onBack: { wentBack = true })
        model.send(.next)
        model.send(.back)
        XCTAssertTrue(player.stopped)
        XCTAssertTrue(wentBack)
    }

    func test_illegalEventsDoNotChangeInformationOrPausedProgress() {
        XCTAssertEqual(reduce(ListenState.information, .ready), .information)
        XCTAssertEqual(reduce(ListenState.information, .resume), .information)
        let paused = ListenState.paused(step: 3, completed: false)
        XCTAssertEqual(reduce(paused, .progress(step: 4, completed: true)), paused)
    }

    private func makeModel(player: FakeListenPlayer, onReady: @escaping () -> Void = {}) -> ListenViewModel {
        ListenViewModel(pattern: PatternCatalog.all[1], bpm: 80, player: player,
                        onReady: onReady, onBack: {})
    }
}

@MainActor
private final class FakeListenPlayer: ListenPatternPlayer {
    var elapsed: TimeInterval = 0
    var starts = 0
    var paused = false
    var stopped = false
    var shouldFail = false
    func start(pattern: StrumPattern, bpm: Int) throws {
        if shouldFail { throw NSError(domain: "ListenTests", code: 1) }
        starts += 1; elapsed = 0; stopped = false; paused = false
    }
    func pause() { paused = true }
    func resume() { paused = false }
    func stop() { stopped = true }
}
