import XCTest
@testable import StrumMeng

final class ReplayTimelineTests: XCTestCase {

    // MARK: songTime

    func test_songTime_atNormalSpeed_advancesWithRealTime() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 2, elapsed: 3, rate: 1, duration: 60), 5)
    }

    func test_songTime_atHalfSpeed_advancesHalfAsFast() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 2, elapsed: 4, rate: 0.5, duration: 60), 4)
    }

    func test_songTime_atOneAndHalfSpeed_advancesFaster() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 0, elapsed: 2, rate: 1.5, duration: 60), 3)
    }

    func test_songTime_neverPassesTheEnd() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 58, elapsed: 10, rate: 1.5, duration: 60), 60)
    }

    func test_songTime_fromTheLeadIn_staysNegativeUntilBeatZero() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: -2, elapsed: 1, rate: 1, duration: 60), -1)
    }

    func test_songTime_ignoresNegativeElapsedTime() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 5, elapsed: -1, rate: 1, duration: 60), 5)
    }

    // MARK: seekTime

    func test_seekTime_mapsProgressOntoTheSession() {
        XCTAssertEqual(ReplayTimeline.seekTime(progress: 0, duration: 60), 0)
        XCTAssertEqual(ReplayTimeline.seekTime(progress: 0.25, duration: 60), 15)
        XCTAssertEqual(ReplayTimeline.seekTime(progress: 1, duration: 60), 60)
    }

    func test_seekTime_clampsADragPastEitherEnd() {
        XCTAssertEqual(ReplayTimeline.seekTime(progress: -0.3, duration: 60), 0)
        XCTAssertEqual(ReplayTimeline.seekTime(progress: 1.4, duration: 60), 60)
    }

    func test_seekTime_withInvalidInput_goesToTheStart() {
        XCTAssertEqual(ReplayTimeline.seekTime(progress: .nan, duration: 60), 0)
        XCTAssertEqual(ReplayTimeline.seekTime(progress: 0.5, duration: 0), 0)
    }

    // MARK: sound timing

    func test_realDelay_scalesWithSpeed() {
        XCTAssertEqual(ReplayTimeline.realDelay(songDelta: 1, rate: 1), 1)
        XCTAssertEqual(ReplayTimeline.realDelay(songDelta: 1, rate: 0.5), 2)
        XCTAssertEqual(ReplayTimeline.realDelay(songDelta: 1.5, rate: 1.5), 1)
    }

    func test_realDelay_withZeroRate_doesNotDivideByZero() {
        XCTAssertEqual(ReplayTimeline.realDelay(songDelta: 1, rate: 0), 1)
    }

    func test_songLookahead_coversTheSameRealTimeAtEverySpeed() {
        XCTAssertEqual(ReplayTimeline.songLookahead(realLookahead: 0.12, rate: 1), 0.12, accuracy: 1e-9)
        XCTAssertEqual(ReplayTimeline.songLookahead(realLookahead: 0.12, rate: 0.5), 0.06, accuracy: 1e-9)
        XCTAssertEqual(ReplayTimeline.songLookahead(realLookahead: 0.12, rate: 1.5), 0.18, accuracy: 1e-9)
    }
}
