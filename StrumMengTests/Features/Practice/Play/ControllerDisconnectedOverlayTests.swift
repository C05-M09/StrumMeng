import XCTest
@testable import StrumMeng

final class ControllerDisconnectedOverlayTests: XCTestCase {
    private func date(step: Int, plus fraction: Double = 0) -> Date {
        Date(timeIntervalSinceReferenceDate: (Double(step) + fraction) * ControllerDisconnectedOverlay.dotStepInterval)
    }

    func test_reconnectingDots_fillOneByOneThenStartAgain() {
        let counts = (0..<8).map { ControllerDisconnectedOverlay.visibleDotCount(at: date(step: $0)) }
        XCTAssertEqual(counts, [0, 1, 2, 3, 0, 1, 2, 3])
    }

    func test_reconnectingDots_holdTheirCountWithinAStep() {
        XCTAssertEqual(ControllerDisconnectedOverlay.visibleDotCount(at: date(step: 2, plus: 0.1)), 2)
        XCTAssertEqual(ControllerDisconnectedOverlay.visibleDotCount(at: date(step: 2, plus: 0.9)), 2)
    }
}
