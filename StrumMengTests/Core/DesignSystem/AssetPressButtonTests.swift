import XCTest
@testable import StrumMeng

final class AssetPressButtonTests: XCTestCase {
    private let size = CGSize(width: 88, height: 96)

    func test_releaseInsideTheButton_counts() {
        XCTAssertTrue(AssetPressButton.isInside(CGPoint(x: 44, y: 48), size: size))
        XCTAssertTrue(AssetPressButton.isInside(CGPoint(x: 1, y: 95), size: size))
    }

    func test_releaseOutsideTheButton_isCancelled() {
        XCTAssertFalse(AssetPressButton.isInside(CGPoint(x: -1, y: 48), size: size))
        XCTAssertFalse(AssetPressButton.isInside(CGPoint(x: 44, y: 97), size: size))
        XCTAssertFalse(AssetPressButton.isInside(CGPoint(x: 120, y: 48), size: size))
    }

    func test_pauseTouchArea_isCentredOnThePauseButton() {
        let layout = PlayScreenLayout(size: PlayScreenLayout.designSize)
        XCTAssertEqual(layout.pauseRect.midX, layout.pauseCenter.x, accuracy: 1e-9)
        XCTAssertEqual(layout.pauseRect.midY, layout.pauseCenter.y, accuracy: 1e-9)
        XCTAssertEqual(layout.pauseRect.width, layout.pauseSize, accuracy: 1e-9)
        XCTAssertGreaterThan(layout.pauseRect.height, layout.pauseRect.width)
    }
}
