import XCTest
@testable import StrumMeng

/// Drives the game loop by hand: ticks, strums and time are injected, nothing waits on real time.
final class PlayViewModelTests: XCTestCase {
    private let start: TimeInterval = 100
    private let step = AudioBeatClock.stepInterval(bpm: 80)    // 0.375 s
    private var currentTime: TimeInterval = 0
    private let clock = MockBeatClock()
    private var finished: [SessionResult] = []
    private var exitCount = 0

    /// Syncopation, "D - D U - U D U": step 0 judged, step 1 a rest.
    private func makeViewModel(patternID: String = "syncopation",
                               repetitions: Int = 10,
                               latencyOffset: TimeInterval = 0,
                               strumArrivalGrace: TimeInterval = 0,
                               touchInput: TouchStrumInput? = nil,
                               controller: ControllerLink? = nil,
                               requiresController: Bool = true,
                               sound: MockGuitarSound? = nil) throws -> PlayViewModel {
        let pattern = try XCTUnwrap(PatternCatalog.all.first { $0.id == patternID })
        return PlayViewModel(
            pattern: pattern, bpm: 80, clock: clock, input: MockStrumInputService(), touchInput: touchInput,
            controller: controller, requiresController: requiresController,
            guitar: sound, metronome: sound, latencyOffset: latencyOffset, strumArrivalGrace: strumArrivalGrace, repetitions: repetitions,
            now: { [unowned self] in self.currentTime },
            waitUntil: { _ in try? await Task.sleep(for: .seconds(3600)) },
            makeID: { UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID() },
            currentDate: { Date(timeIntervalSince1970: 0) },
            onFinished: { [unowned self] in self.finished.append($0) },
            onExit: { [unowned self] in self.exitCount += 1 })
    }

    /// Clock tick n: 0...5 are the count-in, tick 6 is session step 0.
    private func time(ofTick n: Int) -> TimeInterval { start + Double(n) * step }

    private func tick(_ viewModel: PlayViewModel, _ n: Int) {
        currentTime = time(ofTick: n)
        viewModel.handle(BeatTick(index: n, expectedTime: currentTime))
    }

    private func strum(_ viewModel: PlayViewModel, at time: TimeInterval, _ direction: StrumDirection = .down) {
        currentTime = max(currentTime, time)
        viewModel.handle(PracticeFixtures.strum(at: time, direction))
    }

    private func startPlaying(_ viewModel: PlayViewModel) async {
        await viewModel.send(.tapReady)
        for n in 0...6 { tick(viewModel, n) }
    }

    private func nodeResult(_ viewModel: PlayViewModel, step: Int) -> PlayFeedback? {
        viewModel.screenModel().nodes[step].judgement?.feedback
    }

    // MARK: Flow

    func test_startsOnReady_withTheLaneWaiting() throws {
        let model = try makeViewModel().screenModel()
        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.title, "Syncopation Strum")
        XCTAssertEqual(model.bpm, 80)
        XCTAssertEqual(model.duration, 30, accuracy: 1e-9)       // 10 × 8 steps × 0.375 s
        XCTAssertEqual(model.nodes.count, 80)
        XCTAssertNil(model.nodes[1].arrow)                         // rest
    }

    func test_tapReady_startsCountInAndTheClock() async throws {
        let viewModel = try makeViewModel()
        await viewModel.send(.tapReady)
        XCTAssertEqual(viewModel.state, .countIn(3))
        XCTAssertEqual(clock.startedBPMs, [80])
    }

    func test_countIn_countsThreeTwoOneOnQuarterNotes_thenPlaysOnStepZero() async throws {
        let viewModel = try makeViewModel()
        await viewModel.send(.tapReady)
        var seen: [PracticeState] = []
        for n in 0...5 {
            tick(viewModel, n)
            seen.append(viewModel.state)
        }
        XCTAssertEqual(seen, [.countIn(3), .countIn(3), .countIn(2), .countIn(2), .countIn(1), .countIn(1)])
        tick(viewModel, 6)
        XCTAssertEqual(viewModel.state, .playing)
        XCTAssertEqual(viewModel.screenModel().songTime, 0, accuracy: 1e-9)
    }

    func test_strumBeforeReady_isIgnored() throws {
        let viewModel = try makeViewModel()
        strum(viewModel, at: 1)
        XCTAssertTrue(viewModel.beatEvents.isEmpty)
    }

    // MARK: Judging on the nodes

    func test_onTimeStrum_turnsTheNodePerfectRightAway() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6) + 0.01)
        XCTAssertEqual(viewModel.beatEvents.map(\.result), [.perfect])
        XCTAssertEqual(nodeResult(viewModel, step: 0), .perfect)
        XCTAssertEqual(viewModel.screenModel().lastJudgement?.feedback, .perfect)
    }

    func test_strumJustBeforeTheFirstBeat_duringTheCountIn_isPerfect() async throws {
        let viewModel = try makeViewModel()
        await viewModel.send(.tapReady)
        for n in 0...5 { tick(viewModel, n) }
        strum(viewModel, at: time(ofTick: 6) - 0.02)
        tick(viewModel, 6)
        XCTAssertEqual(nodeResult(viewModel, step: 0), .perfect)
    }

    func test_earlyStrum_turnsTheNodeTooEarlyWhenTheWindowCloses() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        tick(viewModel, 7)
        strum(viewModel, at: time(ofTick: 8) - 0.1)
        tick(viewModel, 8)
        XCTAssertNil(nodeResult(viewModel, step: 2))
        currentTime = time(ofTick: 8) + 0.06
        viewModel.closeWindows(upTo: currentTime)
        XCTAssertEqual(nodeResult(viewModel, step: 2), .tooEarly)
    }

    func test_noStrum_turnsTheNodeMiss() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        currentTime = time(ofTick: 6) + 0.06
        viewModel.closeWindows(upTo: currentTime)
        XCTAssertEqual(nodeResult(viewModel, step: 0), .miss)
    }

    func test_lateStrum_isJudgedAsMiss() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6) + 0.08)
        XCTAssertEqual(nodeResult(viewModel, step: 0), .miss)
    }

    func test_everySwipe_isReportedToTheScreen_judgedOrNot() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        tick(viewModel, 7)                                          // step 1 is a rest: nothing to judge
        strum(viewModel, at: time(ofTick: 7))
        XCTAssertEqual(viewModel.screenModel().lastStrumTime ?? -1, step, accuracy: 1e-9)
    }

    func test_aStrumArrivingLate_makesTheRingReactWhenItArrives_butIsJudgedByTouchTime() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        // Touched on the beat, delivered 80 ms later over the network.
        currentTime = time(ofTick: 6) + 0.08
        viewModel.handle(PracticeFixtures.strum(at: time(ofTick: 6), .down))
        XCTAssertEqual(viewModel.screenModel().lastStrumTime ?? -1, 0.08, accuracy: 1e-9)
        XCTAssertEqual(nodeResult(viewModel, step: 0), .perfect)
    }

    func test_wrongDirection_turnsTheNodeMissRightAway() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6) + 0.01, .up)          // step 0 is a down stroke
        XCTAssertEqual(nodeResult(viewModel, step: 0), .miss)
        XCTAssertEqual(viewModel.screenModel().lastJudgement?.feedback, .miss)
    }

    func test_upStep_isPerfectOnlyWithAnUpSwipe() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        for n in 7...9 { tick(viewModel, n) }                       // step 3 is an up stroke
        strum(viewModel, at: time(ofTick: 9) + 0.01, .up)
        XCTAssertEqual(nodeResult(viewModel, step: 3), .perfect)
    }

    func test_latencyOffset_isAppliedWhenJudging() async throws {
        let viewModel = try makeViewModel(latencyOffset: 0.1)
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6) + 0.1)
        XCTAssertEqual(nodeResult(viewModel, step: 0), .perfect)
    }

    func test_restSteps_areNeverJudged() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        for n in 7...14 { tick(viewModel, n) }
        let judged = Set(viewModel.beatEvents.map(\.stepIndex))
        XCTAssertFalse(judged.contains(1))
        XCTAssertFalse(judged.contains(4))
        XCTAssertTrue(judged.isSuperset(of: [0, 2, 3, 5, 6, 7]))
    }

    // MARK: Touch input

    func test_drag_usesTheTouchEventTime_notWhenItWasHandled() throws {
        let spy = SpyTouchStrumInput()
        let viewModel = try makeViewModel(touchInput: spy)
        currentTime = 100                                    // host clock now; currentDate() is t = 0
        viewModel.dragChanged(translation: 15, eventDate: Date(timeIntervalSince1970: -0.05))
        viewModel.dragEnded()
        XCTAssertEqual(spy.drags.first?.translation, 15)
        XCTAssertEqual(spy.drags.first?.time ?? 0, 99.95, accuracy: 1e-6)
        XCTAssertEqual(spy.endCount, 1)
    }

    func test_drag_withAnImplausiblyOldTimestamp_isTimedNow() throws {
        let spy = SpyTouchStrumInput()
        let viewModel = try makeViewModel(touchInput: spy)
        currentTime = 100
        // e.g. a timestamp on another clock: trusting it would push the strum out of every window
        viewModel.dragChanged(translation: 15, eventDate: Date(timeIntervalSince1970: -50_000))
        XCTAssertEqual(spy.drags.first?.time ?? 0, 100, accuracy: 1e-9)
    }

    func test_drag_withATimestampFromTheFuture_isNeverAfterNow() throws {
        let spy = SpyTouchStrumInput()
        let viewModel = try makeViewModel(touchInput: spy)
        currentTime = 100
        viewModel.dragChanged(translation: 15, eventDate: Date(timeIntervalSince1970: 0.2))
        XCTAssertEqual(spy.drags.first?.time ?? 0, 100, accuracy: 1e-9)
    }

    // MARK: Pause, restart, exit

    func test_pause_keepsTheOpenBeatForAfterTheRecount() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        await viewModel.send(.tapPause)
        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertEqual(clock.pauseCount, 1)
        XCTAssertTrue(viewModel.beatEvents.isEmpty, "a pause never produces Miss results")

        await viewModel.send(.tapResume)
        XCTAssertEqual(viewModel.state, .countIn(3))
        XCTAssertEqual(clock.resumeCount, 1)
        for n in 20...25 { tick(viewModel, n) }      // the clock resumes with new indices and times
        tick(viewModel, 26)
        XCTAssertEqual(viewModel.state, .playing)
        strum(viewModel, at: time(ofTick: 26))
        XCTAssertEqual(viewModel.beatEvents.map(\.stepIndex), [0])
        XCTAssertEqual(viewModel.beatEvents.map(\.result), [.perfect])
    }

    func test_restartFromPause_discardsTheSession() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6))
        await viewModel.send(.tapPause)
        await viewModel.send(.tapRestart)
        XCTAssertEqual(viewModel.state, .countIn(3))
        XCTAssertTrue(viewModel.beatEvents.isEmpty)
        XCTAssertEqual(clock.startedBPMs, [80, 80])
    }

    func test_backToMenu_discardsTheSessionAndExits() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        await viewModel.send(.tapPause)
        await viewModel.send(.tapBackToMenu)
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(clock.stopCount, 1)
        XCTAssertEqual(exitCount, 1)
        XCTAssertTrue(finished.isEmpty, "a discarded session never produces a result")
    }

    // MARK: Finish and result

    func test_session_finishesAfterTheLastStep_withOneEventPerJudgedStep() async throws {
        let viewModel = try makeViewModel(repetitions: 1)
        await startPlaying(viewModel)
        for n in 7...14 { tick(viewModel, n) }

        guard case .finished(let result) = viewModel.state else {
            return XCTFail("expected finished, got \(viewModel.state)")
        }
        XCTAssertEqual(result.beatEvents.count, 6)
        XCTAssertEqual(result.missCount, 6)
        XCTAssertEqual(result.patternID, "syncopation")
        XCTAssertEqual(result.bpm, 80)
        XCTAssertEqual(finished, [result])
    }

    func test_sameJudgingLogic_worksForEveryPattern() async throws {
        for pattern in PatternCatalog.all {
            finished = []
            let viewModel = try makeViewModel(patternID: pattern.id, repetitions: 1)
            await startPlaying(viewModel)
            for stepIndex in 0..<pattern.strokes.count {
                let tickIndex = stepIndex + 6
                if stepIndex > 0 { tick(viewModel, tickIndex) }
                switch pattern.strokes[stepIndex] {
                case .down: strum(viewModel, at: time(ofTick: tickIndex) + 0.005, .down)
                case .up: strum(viewModel, at: time(ofTick: tickIndex) + 0.005, .up)
                case .rest: break
                }
            }
            tick(viewModel, 6 + pattern.strokes.count)

            let result = try XCTUnwrap(finished.first, pattern.id)
            XCTAssertEqual(result.perfectCount, pattern.strokes.filter { $0 != .rest }.count, pattern.id)
            XCTAssertEqual(result.accuracy, 1, accuracy: 1e-9, pattern.id)
        }
    }

    // MARK: iPhone controller

    private func makeConnectedViewModel(_ controller: MockControllerLink) async throws -> PlayViewModel {
        let viewModel = try makeViewModel(controller: controller)
        await viewModel.handle(.connected(latencyMs: 5))
        return viewModel
    }

    func test_withoutAController_sessionsStartAsBefore() async throws {
        let viewModel = try makeViewModel()
        XCTAssertTrue(viewModel.isControllerConnected)
        await viewModel.send(.tapReady)
        XCTAssertEqual(viewModel.state, .countIn(3))
    }

    func test_tapReady_whileTheControllerIsNotConnected_isIgnored() async throws {
        let controller = MockControllerLink()
        let viewModel = try makeViewModel(controller: controller)
        await viewModel.handle(.searching)
        await viewModel.send(.tapReady)
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertTrue(clock.startedBPMs.isEmpty)
        XCTAssertTrue(controller.sessionActiveCalls.isEmpty)
    }

    func test_tapReady_withAConnectedController_tellsTheIPhoneTheSessionStarted() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await viewModel.send(.tapReady)
        XCTAssertEqual(viewModel.state, .countIn(3))
        XCTAssertEqual(controller.sessionActiveCalls, [true])
    }

    func test_controllerDisconnectingWhilePlaying_pausesTheSession() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await startPlaying(viewModel)
        await viewModel.handle(.reconnecting)
        XCTAssertEqual(viewModel.state, .paused)
        XCTAssertEqual(clock.pauseCount, 1)
        XCTAssertEqual(controller.sessionActiveCalls, [true, false])
    }

    func test_controllerDisconnectingDuringTheCountIn_pausesTheSession() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await viewModel.send(.tapReady)
        await viewModel.handle(.reconnecting)
        XCTAssertEqual(viewModel.state, .paused)
    }

    func test_controllerDisconnectingWhilePlaying_doesNotJudgeMisses() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await startPlaying(viewModel)
        await viewModel.handle(.reconnecting)
        currentTime = time(ofTick: 20)
        viewModel.closeWindows(upTo: currentTime)
        XCTAssertFalse(viewModel.beatEvents.contains { $0.result == .miss })
    }

    func test_controllerDisconnectingOutsideASession_changesNothing() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await viewModel.handle(.reconnecting)
        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertFalse(viewModel.isControllerConnected)
        XCTAssertTrue(controller.sessionActiveCalls.isEmpty)
    }

    func test_resume_waitsForTheControllerToReconnect() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await startPlaying(viewModel)
        await viewModel.handle(.reconnecting)
        await viewModel.send(.tapResume)
        XCTAssertEqual(viewModel.state, .paused)
        await viewModel.handle(.connected(latencyMs: 8))
        await viewModel.send(.tapResume)
        XCTAssertEqual(viewModel.state, .countIn(3))
        XCTAssertEqual(controller.sessionActiveCalls, [true, false, true])
    }

    func test_tapPause_tellsTheIPhoneTheSessionStopped() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await startPlaying(viewModel)
        await viewModel.send(.tapPause)
        XCTAssertEqual(controller.sessionActiveCalls, [true, false])
    }

    func test_leavingTheScreen_tellsTheIPhoneTheSessionStopped() async throws {
        let controller = MockControllerLink()
        let viewModel = try await makeConnectedViewModel(controller)
        await startPlaying(viewModel)
        await viewModel.onDisappear()
        XCTAssertEqual(controller.sessionActiveCalls.last, false)
    }

    func test_finishing_tellsTheIPhoneTheSessionStopped() async throws {
        let controller = MockControllerLink()
        // Syncopation × 1 repetition = 8 steps; tick 6 is step 0, tick 14 is past the last step.
        let viewModel = try makeViewModel(repetitions: 1, controller: controller)
        await viewModel.handle(.connected(latencyMs: 5))
        await viewModel.send(.tapReady)
        for n in 0...14 { tick(viewModel, n) }
        currentTime = time(ofTick: 14) + 1
        viewModel.closeWindows(upTo: currentTime)
        guard case .finished = viewModel.state else { return XCTFail("Expected finished") }
        for _ in 0..<20 where controller.sessionActiveCalls.last != false { await Task.yield() }
        XCTAssertEqual(controller.sessionActiveCalls.last, false)
    }

    // MARK: Strums arriving late over the network

    func test_strumTouchedInTime_butArrivingAfterTheWindow_isPerfectWithAGrace() async throws {
        let viewModel = try makeViewModel(strumArrivalGrace: 0.15)
        await startPlaying(viewModel)
        // The window has ended (beat + 50 ms) but the iPhone strum is still on its way.
        currentTime = time(ofTick: 6) + 0.07
        viewModel.closeWindows(upTo: currentTime)
        XCTAssertNil(nodeResult(viewModel, step: 0))
        // It arrives, carrying the touch time inside the Perfect window.
        viewModel.handle(PracticeFixtures.strum(at: time(ofTick: 6) + 0.02, .down))
        XCTAssertEqual(nodeResult(viewModel, step: 0), .perfect)
    }

    func test_withoutAGrace_aStrumArrivingAfterTheWindowIsTooLate() async throws {
        let viewModel = try makeViewModel()
        await startPlaying(viewModel)
        currentTime = time(ofTick: 6) + 0.07
        viewModel.closeWindows(upTo: currentTime)
        viewModel.handle(PracticeFixtures.strum(at: time(ofTick: 6) + 0.02, .down))
        XCTAssertEqual(nodeResult(viewModel, step: 0), .miss)
    }

    func test_withAGrace_noStrumIsStillAMissOnceTheGraceHasPassed() async throws {
        let viewModel = try makeViewModel(strumArrivalGrace: 0.15)
        await startPlaying(viewModel)
        currentTime = time(ofTick: 6) + 0.05 + 0.15
        viewModel.closeWindows(upTo: currentTime)
        XCTAssertEqual(nodeResult(viewModel, step: 0), .miss)
    }

    func test_withAGrace_aLateTouchIsStillAMiss() async throws {
        let viewModel = try makeViewModel(strumArrivalGrace: 0.15)
        await startPlaying(viewModel)
        viewModel.handle(PracticeFixtures.strum(at: time(ofTick: 6) + 0.08, .down))
        currentTime = time(ofTick: 6) + 0.25
        viewModel.closeWindows(upTo: currentTime)
        XCTAssertEqual(nodeResult(viewModel, step: 0), .miss)
    }

    // MARK: Optional controller (on-screen swipes work too)

    func test_optionalController_readyWorksWithoutTheIPhone() async throws {
        let controller = MockControllerLink()
        let viewModel = try makeViewModel(controller: controller, requiresController: false)
        await viewModel.handle(.searching)
        await viewModel.send(.tapReady)
        XCTAssertEqual(viewModel.state, .countIn(3))
    }

    func test_optionalController_sessionWithoutTheIPhone_ignoresItDropping() async throws {
        let controller = MockControllerLink()
        let viewModel = try makeViewModel(controller: controller, requiresController: false)
        await viewModel.handle(.searching)
        await startPlaying(viewModel)
        await viewModel.handle(.reconnecting)
        XCTAssertEqual(viewModel.state, .playing)
    }

    func test_optionalController_sessionStartedWithTheIPhone_pausesWhenItDrops() async throws {
        let controller = MockControllerLink()
        let viewModel = try makeViewModel(controller: controller, requiresController: false)
        await viewModel.handle(.connected(latencyMs: 5))
        await startPlaying(viewModel)
        await viewModel.handle(.reconnecting)
        XCTAssertEqual(viewModel.state, .paused)
    }
    // MARK: Sound

    func test_everySwipe_soundsTheGuitar_evenBeforeTheSession() async throws {
        let sound = MockGuitarSound()
        let viewModel = try makeViewModel(sound: sound)

        strum(viewModel, at: 50, .up)
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6), .down)

        XCTAssertEqual(sound.strums, [.init(direction: .up, time: nil, accent: 1),
                                      .init(direction: .down, time: nil, accent: 1)])
    }

    func test_metronome_clicksTheCountInAndTheFirstBeat_onTime() async throws {
        let sound = MockGuitarSound()
        let viewModel = try makeViewModel(sound: sound)

        await startPlaying(viewModel)                     // ticks 0…6

        // Quarter notes: ticks 0, 2, 4 (3-2-1) and 6 (step 0, the bar's first beat, accented).
        XCTAssertEqual(sound.clicks.map(\.accent), [false, false, false, true])
        for (click, tick) in zip(sound.clicks, [0, 2, 4, 6]) {
            XCTAssertEqual(click.time, time(ofTick: tick), accuracy: 1e-9)
        }
    }

    func test_metronome_accentsTheFirstBeatOfEveryBar() async throws {
        let sound = MockGuitarSound()
        let viewModel = try makeViewModel(sound: sound)
        await startPlaying(viewModel)

        for n in 7...13 { tick(viewModel, n) }            // up to step 7; step 8 is scheduled ahead

        XCTAssertEqual(sound.clicks.last?.time ?? 0, time(ofTick: 14), accuracy: 1e-9)
        XCTAssertEqual(sound.clicks.last?.accent, true)
        XCTAssertEqual(sound.clicks.filter(\.accent).count, 2)
    }

    func test_metronome_stopsAtTheEndOfTheSession() async throws {
        let sound = MockGuitarSound()
        let viewModel = try makeViewModel(repetitions: 1, sound: sound)    // steps 0…7
        await startPlaying(viewModel)

        for n in 7...14 { tick(viewModel, n) }

        let lastClick = try XCTUnwrap(sound.clicks.last)
        XCTAssertEqual(lastClick.time, time(ofTick: 12), accuracy: 1e-9, "Step 6 is the last quarter note")
    }

    func test_pause_cancelsScheduledClicks() async throws {
        let sound = MockGuitarSound()
        let viewModel = try makeViewModel(sound: sound)
        await startPlaying(viewModel)

        await viewModel.send(.tapPause)

        XCTAssertGreaterThan(sound.cancelClicksCount, 0)
    }
}
