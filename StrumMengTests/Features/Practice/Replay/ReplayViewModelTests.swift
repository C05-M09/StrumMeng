//
//  ReplayViewModelTests.swift
//  StrumMengTests
//
//  Created by Sharon Tan on 29/10/26.
//

import XCTest
@testable import StrumMeng

@MainActor
final class ReplayViewModelTests: XCTestCase {
    private var currentTime: TimeInterval = 100.0
    private var dismissCount = 0

    private func makeResult(events: [BeatEvent], bpm: Int = 80) -> SessionResult {
        SessionResultBuilder.build(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            patternID: "foundation",
            bpm: bpm,
            beatEvents: events,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func makeViewModel(events: [BeatEvent], bpm: Int = 80) -> ReplayViewModel {
        ReplayViewModel(
            result: makeResult(events: events, bpm: bpm),
            repetitions: 2,
            now: { [unowned self] in self.currentTime },
            onDismiss: { [unowned self] in self.dismissCount += 1 }
        )
    }

    func test_initialState_isReadyWithNoJudgementsApplied() {
        let events = [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0),
            BeatEvent(stepIndex: 2, result: .tooEarly, offsetMs: -50)
        ]
        let vm = makeViewModel(events: events)

        XCTAssertEqual(vm.state, .ready)
        XCTAssertFalse(vm.isAnimating)
        XCTAssertLessThan(vm.songTime(), 0)

        let screen = vm.screenModel()
        XCTAssertEqual(screen.phase, .ready)
        XCTAssertNil(screen.lastJudgement)
        XCTAssertTrue(screen.nodes.allSatisfy { $0.judgement == nil })
    }

    func test_play_startsPlayback() {
        let vm = makeViewModel(events: [])
        vm.send(.play)

        XCTAssertEqual(vm.state, .playing)
        XCTAssertTrue(vm.isAnimating)
    }

    func test_playback_revealsStoredBeatEventsInExactOrderWithoutRejudging() {
        let events = [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: -12),
            BeatEvent(stepIndex: 2, result: .tooEarly, offsetMs: -80),
            BeatEvent(stepIndex: 4, result: .miss, offsetMs: nil)
        ]
        let vm = makeViewModel(events: events)
        let step = vm.stepInterval

        vm.send(.play)

        // 1. Before step 0 is reached (during lead-in)
        XCTAssertNil(vm.screenModel().nodes[0].judgement)
        XCTAssertNil(vm.screenModel().lastJudgement)

        // 2. Advance to step 0
        let timeToStep0 = -vm.songTime()
        vm.advanceTime(by: timeToStep0)

        var screen = vm.screenModel()
        XCTAssertEqual(screen.nodes[0].judgement?.feedback, .perfect)
        XCTAssertEqual(screen.lastJudgement?.feedback, .perfect)
        XCTAssertNil(screen.nodes[2].judgement)

        // 3. Advance to step 2
        vm.advanceTime(by: step * 2)

        screen = vm.screenModel()
        XCTAssertEqual(screen.nodes[0].judgement?.feedback, .perfect)
        XCTAssertEqual(screen.nodes[2].judgement?.feedback, .tooEarly)
        XCTAssertEqual(screen.lastJudgement?.feedback, .tooEarly)
        XCTAssertNil(screen.nodes[4].judgement)

        // 4. Advance to step 4
        vm.advanceTime(by: step * 2)

        screen = vm.screenModel()
        XCTAssertEqual(screen.nodes[0].judgement?.feedback, .perfect)
        XCTAssertEqual(screen.nodes[2].judgement?.feedback, .tooEarly)
        XCTAssertEqual(screen.nodes[4].judgement?.feedback, .miss)
        XCTAssertEqual(screen.lastJudgement?.feedback, .miss)
    }

    func test_pause_freezesSongTime() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        vm.advanceTime(by: 1.0)

        let songTimeBeforePause = vm.songTime()
        vm.send(.pause)

        XCTAssertEqual(vm.state, .paused)
        XCTAssertFalse(vm.isAnimating)

        // Host time moves forward while paused
        currentTime += 5.0
        XCTAssertEqual(vm.songTime(), songTimeBeforePause)

        // Resume playback
        vm.send(.play)
        XCTAssertEqual(vm.state, .playing)
        XCTAssertEqual(vm.songTime(), songTimeBeforePause)

        // Host time moves by 0.5s after resume
        currentTime += 0.5
        XCTAssertEqual(vm.songTime(), songTimeBeforePause + 0.5, accuracy: 0.001)
    }

    func test_restart_resetsPlaybackToInitialTime() {
        let events = [BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0)]
        let vm = makeViewModel(events: events)
        vm.send(.play)
        vm.advanceTime(by: 2.0)

        XCTAssertNotNil(vm.screenModel().nodes[0].judgement)

        vm.send(.restart)
        XCTAssertEqual(vm.state, .playing)
        XCTAssertLessThan(vm.songTime(), 0)
        XCTAssertNil(vm.screenModel().nodes[0].judgement)
    }

    func test_reachingDuration_transitionsToFinished() {
        let vm = makeViewModel(events: [])
        vm.send(.play)

        vm.advanceTime(by: vm.duration + 2.0)
        XCTAssertEqual(vm.state, .finished)
        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(dismissCount, 1)
    }

    func test_backToSummary_callsOnDismiss() {
        let vm = makeViewModel(events: [])
        vm.send(.backToSummary)

        XCTAssertEqual(vm.state, .dismissed)
        XCTAssertEqual(dismissCount, 1)
    }
}
