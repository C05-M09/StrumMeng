import XCTest
@testable import StrumMeng

final class SwipeTrackerTests: XCTestCase {
    func test_movementBelowThreshold_firesNothing() {
        var tracker = SwipeTracker()
        XCTAssertNil(tracker.feed(5, threshold: 12))
        XCTAssertNil(tracker.feed(5, threshold: 12))
    }

    func test_movingDownPastThreshold_firesDown() {
        var tracker = SwipeTracker()
        XCTAssertNil(tracker.feed(8, threshold: 12))
        XCTAssertEqual(tracker.feed(8, threshold: 12), .down)
    }

    func test_movingUpPastThreshold_firesUp() {
        var tracker = SwipeTracker()
        XCTAssertEqual(tracker.feed(-15, threshold: 12), .up)
    }

    func test_continuingInTheSameDirection_doesNotFireAgain() {
        var tracker = SwipeTracker()
        XCTAssertEqual(tracker.feed(15, threshold: 12), .down)
        XCTAssertNil(tracker.feed(50, threshold: 12))
    }

    func test_reversingInsideOneGesture_firesTheOtherDirection() {
        var tracker = SwipeTracker()
        XCTAssertEqual(tracker.feed(30, threshold: 12), .down)
        XCTAssertNil(tracker.feed(-10, threshold: 12))
        XCTAssertEqual(tracker.feed(-5, threshold: 12), .up)
        XCTAssertEqual(tracker.feed(20, threshold: 12), .down)
    }

    func test_reset_forgetsTheLastDirection() {
        var tracker = SwipeTracker()
        XCTAssertEqual(tracker.feed(15, threshold: 12), .down)
        tracker.reset()
        XCTAssertEqual(tracker.feed(15, threshold: 12), .down)
    }
}
