import XCTest
@testable import StrumMeng

final class OptionSliderGeometryTests: XCTestCase {
    // A 300-wide track whose pick stops 20 in from each end: the pick's centre travels from 20 to 280.
    private let track: CGFloat = 300
    private let endInset: CGFloat = 20

    func test_touchAtLeftEndOfTravel_givesMinimum() {
        XCTAssertEqual(OptionSliderGeometry.value(atX: 20, trackWidth: track, endInset: endInset),
                       VolumeConfig.minimum, accuracy: 0.0001)
    }

    func test_touchAtRightEndOfTravel_givesMaximum() {
        XCTAssertEqual(OptionSliderGeometry.value(atX: 280, trackWidth: track, endInset: endInset),
                       VolumeConfig.maximum, accuracy: 0.0001)
    }

    func test_touchInTheMiddle_givesHalf() {
        XCTAssertEqual(OptionSliderGeometry.value(atX: 150, trackWidth: track, endInset: endInset),
                       0.5, accuracy: 0.0001)
    }

    func test_touchBeyondEitherEnd_isClamped() {
        XCTAssertEqual(OptionSliderGeometry.value(atX: -100, trackWidth: track, endInset: endInset),
                       VolumeConfig.minimum, accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.value(atX: 900, trackWidth: track, endInset: endInset),
                       VolumeConfig.maximum, accuracy: 0.0001)
    }

    func test_touchBetweenSteps_snapsToTheNearestStep() {
        // 20 + 0.33 * 260 = 105.8 → 0.3; 20 + 0.36 * 260 = 113.6 → 0.4
        XCTAssertEqual(OptionSliderGeometry.value(atX: 105.8, trackWidth: track, endInset: endInset),
                       0.3, accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.value(atX: 113.6, trackWidth: track, endInset: endInset),
                       0.4, accuracy: 0.0001)
    }

    func test_trackWithNoRoomToTravel_givesMinimumInsteadOfDividingByZero() {
        XCTAssertEqual(OptionSliderGeometry.value(atX: 10, trackWidth: 40, endInset: 20),
                       VolumeConfig.minimum, accuracy: 0.0001)
    }

    func test_thumbCentre_stopsAtTheEndInsetAtMinimumAndMaximum() {
        XCTAssertEqual(OptionSliderGeometry.thumbCenterX(for: 0, trackWidth: track, endInset: endInset), 20,
                       accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.thumbCenterX(for: 0.5, trackWidth: track, endInset: endInset), 150,
                       accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.thumbCenterX(for: 1, trackWidth: track, endInset: endInset), 280,
                       accuracy: 0.0001)
    }

    func test_thumbCentre_forOutOfRangeVolume_staysOnTheTrack() {
        XCTAssertEqual(OptionSliderGeometry.thumbCenterX(for: 2, trackWidth: track, endInset: endInset), 280,
                       accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.thumbCenterX(for: -1, trackWidth: track, endInset: endInset), 20,
                       accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.thumbCenterX(for: .nan, trackWidth: track, endInset: endInset),
                       OptionSliderGeometry.thumbCenterX(for: VolumeConfig.defaultVolume, trackWidth: track,
                                                         endInset: endInset),
                       accuracy: 0.0001)
    }

    func test_touchAtThumbCentre_givesBackTheSameVolume() {
        for tenth in 0...10 {
            let volume = Double(tenth) / 10
            let x = OptionSliderGeometry.thumbCenterX(for: volume, trackWidth: track, endInset: endInset)
            XCTAssertEqual(OptionSliderGeometry.value(atX: x, trackWidth: track, endInset: endInset), volume,
                           accuracy: 0.0001)
        }
    }

    func test_movedBy_stepsUpAndDown_andStopsAtTheEnds() {
        XCTAssertEqual(OptionSliderGeometry.value(0.5, movedBy: 1), 0.6, accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.value(0.5, movedBy: -1), 0.4, accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.value(1, movedBy: 1), 1, accuracy: 0.0001)
        XCTAssertEqual(OptionSliderGeometry.value(0, movedBy: -1), 0, accuracy: 0.0001)
    }
}
