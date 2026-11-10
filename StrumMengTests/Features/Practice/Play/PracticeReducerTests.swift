import XCTest
@testable import StrumMeng

final class PracticeReducerTests: XCTestCase {
    private let result = SessionResultBuilder.build(id: UUID(), patternID: "foundation", bpm: 80, beatEvents: [],
                                                    createdAt: Date(timeIntervalSince1970: 0))

    func test_listenFlow_goesIdleToListeningToReady() {
        XCTAssertEqual(reduce(.idle, .startListening), .listening)
        XCTAssertEqual(reduce(.listening, .replayExample), .listening)
        XCTAssertEqual(reduce(.listening, .tapNext), .ready)
    }

    func test_tapReady_startsCountInAtThree() {
        XCTAssertEqual(reduce(.ready, .tapReady), .countIn(3))
    }

    func test_countInTick_countsDownAndStopsAtOne() {
        XCTAssertEqual(reduce(.countIn(3), .countInTick), .countIn(2))
        XCTAssertEqual(reduce(.countIn(2), .countInTick), .countIn(1))
        XCTAssertEqual(reduce(.countIn(1), .countInTick), .countIn(1))
    }

    func test_countInDone_startsPlaying() {
        XCTAssertEqual(reduce(.countIn(1), .countInDone), .playing)
    }

    func test_pauseAndBackground_pauseWhilePlayingOrCountingIn() {
        for event in [PracticeEvent.tapPause, .appMovedToBackground] {
            XCTAssertEqual(reduce(.playing, event), .paused)
            XCTAssertEqual(reduce(.countIn(2), event), .paused)
        }
    }

    func test_controllerDisconnected_whileCountingInPlayingOrPaused_goesToDisconnected() {
        for state in [PracticeState.countIn(2), .playing, .paused] {
            XCTAssertEqual(reduce(state, .controllerDisconnected), .disconnected)
        }
    }

    func test_controllerDisconnected_outsideASession_isIgnored() {
        for state in [PracticeState.idle, .listening, .ready, .disconnected, .finished(result)] {
            XCTAssertEqual(reduce(state, .controllerDisconnected), state)
        }
    }

    func test_resume_fromDisconnected_countsInAgain() {
        XCTAssertEqual(reduce(.disconnected, .tapResume), .countIn(3))
    }

    func test_disconnected_ignoresPauseRestartAndBackground() {
        for event in [PracticeEvent.tapPause, .tapRestart, .appMovedToBackground, .countInDone] {
            XCTAssertEqual(reduce(.disconnected, event), .disconnected)
        }
    }

    func test_disconnectResumeFinish_sequence() {
        var state = PracticeState.playing
        for event in [PracticeEvent.controllerDisconnected, .tapResume, .countInDone, .sessionEnded(result)] {
            state = reduce(state, event)
        }
        XCTAssertEqual(state, .finished(result))
    }

    func test_resumeAndRestart_fromPaused_countInAgain() {
        XCTAssertEqual(reduce(.paused, .tapResume), .countIn(3))
        XCTAssertEqual(reduce(.paused, .tapRestart), .countIn(3))
    }

    func test_sessionEnded_whilePlaying_finishesWithTheResult() {
        XCTAssertEqual(reduce(.playing, .sessionEnded(result)), .finished(result))
    }

    func test_retryFromFinished_goesToReady() {
        XCTAssertEqual(reduce(.finished(result), .tapRestart), .ready)
    }

    func test_backToMenu_returnsToIdle() {
        for state in [PracticeState.listening, .ready, .paused, .disconnected, .finished(result)] {
            XCTAssertEqual(reduce(state, .tapBackToMenu), .idle)
        }
    }

    func test_pauseResumeFinish_sequence() {
        var state = PracticeState.playing
        for event in [PracticeEvent.tapPause, .tapResume, .countInDone, .sessionEnded(result)] {
            state = reduce(state, event)
        }
        XCTAssertEqual(state, .finished(result))
    }

    func test_illegalEvents_areIgnored() {
        XCTAssertEqual(reduce(.playing, .tapReady), .playing)
        XCTAssertEqual(reduce(.playing, .tapBackToMenu), .playing)
        XCTAssertEqual(reduce(.ready, .tapPause), .ready)
        XCTAssertEqual(reduce(.idle, .tapReady), .idle)
        XCTAssertEqual(reduce(.paused, .countInDone), .paused)
        XCTAssertEqual(reduce(.countIn(3), .sessionEnded(result)), .countIn(3))
        XCTAssertEqual(reduce(.finished(result), .tapPause), .finished(result))
    }
}
