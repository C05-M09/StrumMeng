import XCTest
@testable import StrumMeng

final class ShowtimeReducerTests: XCTestCase {
    private var result: SessionResult {
        SessionResult(id: UUID(), patternID: "foundation", songID: "dummy-twinkle", bpm: 80,
                      accuracy: 1, perfectCount: 1, tooEarlyCount: 0, missCount: 0,
                      createdAt: Date(timeIntervalSince1970: 0), beatEvents: [])
    }
    func test_fullFlowUnlocksReadyAfterAllRequiredPreviewLoopsAreComplete() {
        var state = ShowtimeState.intro
        XCTAssertEqual(reduce(state, .ready), .intro)
        state = reduce(state, .next)
        XCTAssertEqual(state, .listening(0))
        XCTAssertEqual(reduce(state, .ready), state)
        state = reduce(state, .previewStep(7))
        XCTAssertEqual(state, .listening(7))
        XCTAssertEqual(reduce(state, .ready), state)
        state = reduce(state, .previewFinished)
        XCTAssertEqual(state, .ready)
        state = reduce(state, .ready)
        XCTAssertEqual(state, .countIn(3))
        state = reduce(state, .countdown(2))
        XCTAssertEqual(state, .countIn(2))
        state = reduce(state, .countdown(1))
        XCTAssertEqual(state, .countIn(1))
        state = reduce(state, .firstBeat)
        XCTAssertEqual(state, .playing)
        let finished = result
        XCTAssertEqual(reduce(state, .completed(finished)), .finished(finished))
    }
    func test_eachLiveStagePausesForUserBackgroundOrConnection() {
        let stages: [(ShowtimeState, ShowtimeStage)] = [
            (.listening(6), .listening(6)), (.ready, .ready), (.countIn(2), .countIn(2)), (.playing, .playing)]
        for (state, stage) in stages {
            for reason in [ShowtimePauseReason.user, .background, .connection] {
                XCTAssertEqual(reduce(state, .pause(reason)), .paused(stage, reason))
            }
        }
    }
    func test_resumeRestoresPreviewButRecountsGameplay() {
        XCTAssertEqual(reduce(.paused(.listening(3), .user), .resume), .listening(3))
        XCTAssertEqual(reduce(.paused(.ready, .connection), .resume), .ready)
        XCTAssertEqual(reduce(.paused(.countIn(1), .background), .resume), .countIn(3))
        XCTAssertEqual(reduce(.paused(.playing, .connection), .resume), .countIn(3))
    }
    func test_restartDiscardsPositionAndResults() {
        XCTAssertEqual(reduce(.paused(.listening(80), .user), .restart), .listening(0))
        XCTAssertEqual(reduce(.paused(.ready, .user), .restart), .listening(0))
        XCTAssertEqual(reduce(.paused(.playing, .user), .restart), .countIn(3))
        XCTAssertEqual(reduce(.paused(.countIn(1), .user), .restart), .countIn(3))
        XCTAssertEqual(reduce(.finished(result), .restart), .listening(0))
    }
    func test_switchingPatternRelocksReadyAndLateStepsKeepReadiness() {
        XCTAssertEqual(reduce(.listening(4), .selectPattern(1)), .listening(0))
        XCTAssertEqual(reduce(.ready, .selectPattern(1)), .listening(0))
        XCTAssertEqual(reduce(.ready, .selectPattern(-1)), .ready)
        XCTAssertEqual(reduce(.ready, .previewStep(2)), .ready)
        XCTAssertEqual(reduce(.playing, .selectPattern(1)), .playing)
        XCTAssertEqual(reduce(.paused(.listening(2), .user), .selectPattern(1)), .paused(.listening(2), .user))
    }
    func test_backExitsFromEveryStageAndCannotBeRevived() {
        let states: [ShowtimeState] = [.intro, .listening(7), .ready, .countIn(2), .playing,
                                     .paused(.playing, .connection), .finished(result), .exited]
        for state in states { XCTAssertEqual(reduce(state, .back), .exited) }
        XCTAssertEqual(reduce(.exited, .next), .exited)
        XCTAssertEqual(reduce(.exited, .restart), .exited)
    }
    func test_illegalAndLateEventsCannotSkipPreviewOrFinishPausedSessions() {
        let finished = result
        for state in [ShowtimeState.intro, .listening(7), .ready, .paused(.playing, .user)] {
            XCTAssertEqual(reduce(state, .firstBeat), state)
            XCTAssertEqual(reduce(state, .completed(finished)), state)
        }
        XCTAssertEqual(reduce(.paused(.listening(7), .user), .previewFinished), .paused(.ready, .user))
        XCTAssertEqual(reduce(.playing, .previewFinished), .playing)
        XCTAssertEqual(reduce(.countIn(2), .countdown(0)), .countIn(2))
        XCTAssertEqual(reduce(.intro, .pause(.connection)), .intro)
        XCTAssertEqual(reduce(.paused(.playing, .user), .pause(.connection)), .paused(.playing, .connection))
    }
}
