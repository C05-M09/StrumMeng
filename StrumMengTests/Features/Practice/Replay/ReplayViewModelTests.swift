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
        currentTime += 1.0

        let songTimeBeforePause = vm.songTime()
        vm.send(.pause)

        XCTAssertEqual(vm.state, .paused)
        XCTAssertFalse(vm.isAnimating)

        // Host time moves forward while paused
        currentTime += 5.0
        XCTAssertEqual(vm.songTime(), songTimeBeforePause)

        // Resume playback
        vm.send(.resume)
        XCTAssertEqual(vm.state, .playing)
        XCTAssertEqual(vm.songTime(), songTimeBeforePause)

        // Host time moves by 0.5s after resume
        currentTime += 0.5
        XCTAssertEqual(vm.songTime(), songTimeBeforePause + 0.5, accuracy: 0.001)
    }

    func test_resume_continuesFromPausedPosition() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        currentTime += 2.0

        let timeAtPause = vm.songTime()
        vm.send(.pause)

        currentTime += 10.0
        XCTAssertEqual(vm.songTime(), timeAtPause)

        vm.send(.resume)
        XCTAssertEqual(vm.state, .playing)
        XCTAssertEqual(vm.songTime(), timeAtPause)

        currentTime += 1.0
        XCTAssertEqual(vm.songTime(), timeAtPause + 1.0, accuracy: 0.001)
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

    // MARK: - Speed

    func test_speed_startsAtNormal() {
        let vm = makeViewModel(events: [])

        XCTAssertEqual(vm.speed, .normal)
    }

    func test_cycleSpeed_changesTheSpeed_butNotTheState() {
        let vm = makeViewModel(events: [])

        vm.send(.cycleSpeed)
        XCTAssertEqual(vm.speed, .oneAndHalf)
        XCTAssertEqual(vm.state, .ready)

        vm.send(.play)
        vm.send(.cycleSpeed)
        XCTAssertEqual(vm.speed, .half)
        XCTAssertEqual(vm.state, .playing)
    }

    func test_halfSpeed_songTimeAdvancesHalfAsFast() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        vm.send(.cycleSpeed)   // 1.5x
        vm.send(.cycleSpeed)   // 0.5x
        let start = vm.songTime()

        currentTime += 2

        XCTAssertEqual(vm.songTime(), start + 1, accuracy: 0.001)
    }

    func test_changingSpeed_whilePlaying_keepsThePosition() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        currentTime += 1
        let position = vm.songTime()

        vm.send(.cycleSpeed)

        XCTAssertEqual(vm.songTime(), position, accuracy: 0.001)
        currentTime += 1
        XCTAssertEqual(vm.songTime(), position + 1.5, accuracy: 0.001)
    }

    func test_speed_isKeptAcrossPauseAndRestart() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        vm.send(.cycleSpeed)
        vm.send(.pause)
        vm.send(.restart)
        let start = vm.songTime()

        currentTime += 2

        XCTAssertEqual(vm.speed, .oneAndHalf)
        XCTAssertEqual(vm.songTime(), start + 3, accuracy: 0.001)
    }

    // MARK: - Seek

    func test_seek_beforePlay_staysReady_andPlaybackStartsThere() {
        let vm = makeViewModel(events: [])

        vm.send(.seek(progress: 0.5))
        XCTAssertEqual(vm.state, .ready)
        XCTAssertEqual(vm.songTime(), vm.duration * 0.5, accuracy: 0.001)

        vm.send(.play)
        currentTime += 1
        XCTAssertEqual(vm.songTime(), vm.duration * 0.5 + 1, accuracy: 0.001)
    }

    func test_seek_whilePlaying_continuesFromTheNewPosition() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        currentTime += 1

        vm.send(.seek(progress: 0.25))

        XCTAssertEqual(vm.state, .playing)
        XCTAssertEqual(vm.songTime(), vm.duration * 0.25, accuracy: 0.001)
        currentTime += 1
        XCTAssertEqual(vm.songTime(), vm.duration * 0.25 + 1, accuracy: 0.001)
    }

    func test_seek_whilePaused_movesThePosition_andStaysPaused() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        vm.send(.pause)

        vm.send(.seek(progress: 0.5))
        currentTime += 5

        XCTAssertEqual(vm.state, .paused)
        XCTAssertEqual(vm.songTime(), vm.duration * 0.5, accuracy: 0.001)
    }

    func test_seek_showsStoredColoursUpToTheNewPosition_withoutRejudging() {
        let events = [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0),
            BeatEvent(stepIndex: 2, result: .tooEarly, offsetMs: -50)
        ]
        let vm = makeViewModel(events: events)
        vm.send(.play)

        vm.send(.seek(progress: 1.5 * vm.stepInterval / vm.duration))   // between step 0 and step 2
        var screen = vm.screenModel()
        XCTAssertEqual(screen.nodes[0].judgement?.feedback, .perfect)
        XCTAssertNil(screen.nodes[2].judgement)

        vm.send(.seek(progress: 2.5 * vm.stepInterval / vm.duration))   // just past step 2
        screen = vm.screenModel()
        XCTAssertEqual(screen.nodes[2].judgement?.feedback, .tooEarly)

        vm.send(.seek(progress: 0))                                      // back to the start
        screen = vm.screenModel()
        XCTAssertNil(screen.nodes[2].judgement, "Seeking back hides colours not reached yet")
    }

    func test_seek_clampsOutOfRangeProgress() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        vm.send(.pause)

        vm.send(.seek(progress: -1))
        XCTAssertEqual(vm.songTime(), 0, accuracy: 0.001)

        vm.send(.seek(progress: 2))
        XCTAssertEqual(vm.songTime(), vm.duration, accuracy: 0.001)
    }

    func test_seek_afterFinish_isIgnored() {
        let vm = makeViewModel(events: [])
        vm.send(.play)
        vm.advanceTime(by: vm.duration - vm.songTime() + 1)   // from the lead-in to past the end
        XCTAssertEqual(vm.state, .finished)

        vm.send(.seek(progress: 0.1))

        XCTAssertEqual(vm.state, .finished)
        XCTAssertEqual(vm.songTime(), vm.duration, accuracy: 0.001)
        XCTAssertEqual(dismissCount, 1)
    }
}
