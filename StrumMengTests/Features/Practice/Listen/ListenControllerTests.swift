import XCTest
@testable import StrumMeng

/// Practice Listen follows the iPhone like Showtime's listen stage: Play needs it.
@MainActor
final class ListenControllerTests: XCTestCase {
    private func makeModel(withController: Bool = true, controller given: MockControllerLink? = nil,
                           onReady: @escaping () -> Void = {},
                           onSetUpDevice: @escaping () -> Void = {}) -> (ListenViewModel, CountingListenPlayer) {
        let player = CountingListenPlayer()
        let controller = given ?? (withController ? MockControllerLink() : nil)
        let model = ListenViewModel(pattern: PatternCatalog.all[1], bpm: 80, player: player,
                                    history: KnownHistory(),
                                    guidanceStore: InMemoryPracticeGuidanceStore(hasCompletedGuidance: true),
                                    controller: controller,
                                    onSetUpDevice: onSetUpDevice, onReady: onReady, onBack: {})
        return (model, player)
    }

    /// Plays one full loop, so Ready is allowed.
    private func finishLoop(_ model: ListenViewModel, _ player: CountingListenPlayer) {
        model.send(.next)
        player.elapsed = 3
        model.refreshProgress()
    }

    // MARK: Reducer

    func test_aDrop_whileListeningOrPaused_waitsAsDisconnected() {
        XCTAssertEqual(reduce(.listening(step: 2, completed: false), .controllerDisconnected),
                       .disconnected(step: 2, completed: false))
        XCTAssertEqual(reduce(.paused(step: 2, completed: true), .controllerDisconnected),
                       .disconnected(step: 2, completed: true))
    }

    func test_aDrop_elsewhere_isIgnored() {
        XCTAssertEqual(reduce(.information, .controllerDisconnected), .information)
        XCTAssertEqual(reduce(.instructions(step: 1), .controllerDisconnected), .instructions(step: 1))
        XCTAssertEqual(reduce(.departed, .controllerDisconnected), .departed)
    }

    func test_readyWithoutController_needsAFullLoop() {
        XCTAssertEqual(reduce(.listening(step: 3, completed: true), .readyWithoutController),
                       .disconnected(step: 3, completed: true))
        XCTAssertEqual(reduce(.listening(step: 3, completed: false), .readyWithoutController),
                       .listening(step: 3, completed: false))
    }

    func test_resumeFromDisconnected_goesBackToListening_andBackLeaves() {
        XCTAssertEqual(reduce(.disconnected(step: 3, completed: true), .resume),
                       .listening(step: 3, completed: true))
        XCTAssertEqual(reduce(.disconnected(step: 3, completed: true), .back), .departed)
        XCTAssertEqual(reduce(.disconnected(step: 3, completed: true), .ready),
                       .disconnected(step: 3, completed: true))
    }

    // MARK: View model

    func test_ready_withTheIPhoneConnected_goesOn() async {
        var readies = 0
        let (model, player) = makeModel(onReady: { readies += 1 })
        model.handle(.connected(latencyMs: 5))
        finishLoop(model, player)
        for _ in 0..<100 { await Task.yield() }

        model.send(.ready)

        XCTAssertEqual(model.state, .departed)
        XCTAssertEqual(readies, 1)
    }

    func test_ready_withoutTheIPhone_showsDisconnected_andPausesTheExample() {
        var readies = 0
        let (model, player) = makeModel(onReady: { readies += 1 })
        model.handle(.searching)
        finishLoop(model, player)

        model.send(.ready)

        XCTAssertEqual(model.state, .disconnected(step: 0, completed: true))
        XCTAssertEqual(player.pauses, 1)
        XCTAssertEqual(readies, 0)
    }

    func test_aDropWhileListening_pausesTheExample() {
        let (model, player) = makeModel()
        model.handle(.connected(latencyMs: 5))
        model.send(.next)

        model.handle(.reconnecting)

        XCTAssertEqual(model.state, .disconnected(step: 0, completed: false))
        XCTAssertFalse(model.isControllerConnected)
        XCTAssertEqual(player.pauses, 1)
    }

    func test_aDropFromThePauseMenu_doesNotPauseTwice() {
        let (model, player) = makeModel()
        model.handle(.connected(latencyMs: 5))
        model.send(.next)
        model.send(.pause)

        model.handle(.reconnecting)

        XCTAssertEqual(model.state, .disconnected(step: 0, completed: false))
        XCTAssertEqual(player.pauses, 1)
    }

    func test_resume_waitsForTheIPhone_thenContinuesTheExample() {
        let (model, player) = makeModel()
        model.handle(.connected(latencyMs: 5))
        model.send(.next)
        model.handle(.reconnecting)

        model.send(.resume)
        XCTAssertEqual(model.state, .disconnected(step: 0, completed: false))
        XCTAssertEqual(player.resumes, 0)

        model.handle(.connected(latencyMs: 5))
        model.send(.resume)
        XCTAssertEqual(model.state, .listening(step: 0, completed: false))
        XCTAssertEqual(player.resumes, 1)
        model.stop()
    }

    func test_setUpDevice_onlyFromTheDisconnectedPopup() {
        var requests = 0
        let (model, player) = makeModel(onSetUpDevice: { requests += 1 })
        model.handle(.connected(latencyMs: 5))
        model.send(.next)
        model.requestDeviceSetup()
        XCTAssertEqual(requests, 0)

        model.handle(.reconnecting)
        model.requestDeviceSetup()
        XCTAssertEqual(requests, 1)
        _ = player
    }

    func test_withoutAController_readyGoesOnAsBefore() async {
        var readies = 0
        let (model, player) = makeModel(withController: false, onReady: { readies += 1 })
        finishLoop(model, player)
        for _ in 0..<100 { await Task.yield() }

        model.send(.ready)

        XCTAssertEqual(readies, 1)
    }

    func test_appear_followsTheLinkStates() async {
        let controller = MockControllerLink()
        let (model, _) = makeModel(controller: controller)
        model.appear()
        controller.emit(.connected(latencyMs: 5))
        for _ in 0..<1000 where !model.isControllerConnected { await Task.yield() }
        XCTAssertTrue(model.isControllerConnected)
        model.disappear()
    }
}

private struct KnownHistory: SessionHistoryChecking {
    func hasSavedSessions() async throws -> Bool { true }
}

@MainActor
private final class CountingListenPlayer: ListenPatternPlayer {
    var elapsed: TimeInterval = 0
    private(set) var pauses = 0
    private(set) var resumes = 0
    func start(pattern: StrumPattern, bpm: Int) throws { elapsed = 0 }
    func pause() { pauses += 1 }
    func resume() { resumes += 1 }
    func stop() {}
}
