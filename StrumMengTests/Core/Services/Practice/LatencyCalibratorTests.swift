import XCTest
@testable import StrumMeng

final class LatencyCalibratorTests: XCTestCase {
    private let beat: TimeInterval = 0.75    // quarter notes at 80 BPM

    func test_strumOnTheBeat_hasNoOffset() {
        XCTAssertEqual(LatencyCalibrator.offset(ofStrumAt: 3 * beat, beatInterval: beat), 0, accuracy: 1e-9)
    }

    func test_lateStrum_hasAPositiveOffset() {
        XCTAssertEqual(LatencyCalibrator.offset(ofStrumAt: 2 * beat + 0.04, beatInterval: beat), 0.04, accuracy: 1e-9)
    }

    func test_earlyStrum_hasANegativeOffset() {
        XCTAssertEqual(LatencyCalibrator.offset(ofStrumAt: 2 * beat - 0.06, beatInterval: beat), -0.06, accuracy: 1e-9)
    }

    func test_strumBeforeTheFirstBeat_isMeasuredAgainstBeatZero() {
        XCTAssertEqual(LatencyCalibrator.offset(ofStrumAt: -0.03, beatInterval: beat), -0.03, accuracy: 1e-9)
    }

    func test_offset_isMeasuredAgainstTheNearestBeat() {
        // Just past halfway to the next beat: the next one is nearer.
        XCTAssertEqual(LatencyCalibrator.offset(ofStrumAt: beat * 1.6, beatInterval: beat), -0.4 * beat, accuracy: 1e-9)
    }

    func test_zeroBeatInterval_givesNoOffset() {
        XCTAssertEqual(LatencyCalibrator.offset(ofStrumAt: 1.23, beatInterval: 0), 0)
    }

    func test_estimate_isTheMedianOffset() throws {
        let offsets = [0.03, 0.05, 0.04, 0.06, 0.02, 0.05, 0.04, 0.045, 0.035]
        XCTAssertEqual(try XCTUnwrap(LatencyCalibrator.estimate(from: offsets)), 0.04, accuracy: 1e-9)
    }

    func test_estimate_withAnEvenCount_averagesTheMiddleTwo() throws {
        let offsets = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08]
        XCTAssertEqual(try XCTUnwrap(LatencyCalibrator.estimate(from: offsets)), 0.045, accuracy: 1e-9)
    }

    func test_aFewSloppyStrums_barelyMoveTheEstimate() throws {
        let steady = Array(repeating: 0.04, count: 10)
        let sloppy = [0.2, -0.2]
        XCTAssertEqual(try XCTUnwrap(LatencyCalibrator.estimate(from: steady + sloppy)), 0.04, accuracy: 1e-9)
    }

    func test_strumsFarFromAnyBeat_areIgnored() throws {
        let aimed = Array(repeating: -0.02, count: 8)
        let stray = [0.3, -0.35, 0.4]
        XCTAssertEqual(try XCTUnwrap(LatencyCalibrator.estimate(from: aimed + stray)), -0.02, accuracy: 1e-9)
    }

    func test_tooFewUsableStrums_giveNoEstimate() {
        let offsets = Array(repeating: 0.03, count: LatencyCalibrator.minimumSamples - 1) + [0.4, 0.5]
        XCTAssertNil(LatencyCalibrator.estimate(from: offsets))
    }

    func test_noStrums_giveNoEstimate() {
        XCTAssertNil(LatencyCalibrator.estimate(from: []))
    }
}
