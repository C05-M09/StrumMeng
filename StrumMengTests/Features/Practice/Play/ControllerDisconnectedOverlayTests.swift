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

    func test_overlay_initializesWithBackButton() {
        var backTapped = false
        var resumeTapped = false
        var setUpTapped = false

        let overlay = ControllerDisconnectedOverlay(
            unit: 1,
            isReconnected: false,
            backButtonPosition: CGPoint(x: 106, y: 104),
            onBack: { backTapped = true },
            onResume: { resumeTapped = true },
            onSetUpDevice: { setUpTapped = true }
        )

        XCTAssertNotNil(overlay)
        XCTAssertEqual(overlay.backButtonPosition, CGPoint(x: 106, y: 104))
        XCTAssertNotNil(overlay.onBack)
        overlay.onBack?()
        XCTAssertTrue(backTapped)
    }
}
