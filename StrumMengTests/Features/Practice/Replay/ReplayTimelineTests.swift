import XCTest
@testable import StrumMeng

final class ReplayTimelineTests: XCTestCase {

    // MARK: songTime

    func test_songTime_advancesWithRealTime() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 2, elapsed: 3, duration: 60), 5)
    }

    func test_songTime_neverPassesTheEnd() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 58, elapsed: 10, duration: 60), 60)
    }

    func test_songTime_fromTheLeadIn_staysNegativeUntilBeatZero() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: -2, elapsed: 1, duration: 60), -1)
    }

    func test_songTime_ignoresNegativeElapsedTime() {
        XCTAssertEqual(ReplayTimeline.songTime(anchor: 5, elapsed: -1, duration: 60), 5)
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
}
