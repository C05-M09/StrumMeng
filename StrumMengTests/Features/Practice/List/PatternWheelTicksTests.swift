import XCTest
@testable import StrumMeng

final class PatternWheelTicksTests: XCTestCase {
    private func slot(selected: Int, angle: Double, count: Int = 5) -> Int {
        PatternWheelTicks.slot(selectedIndex: selected, dragAngle: angle, angleBetween: 30, count: count)
    }

    // MARK: slot

    func test_slot_withoutTurning_isTheSelectedPattern() {
        XCTAssertEqual(slot(selected: 2, angle: 0), 2)
    }

    func test_slot_turningBackOnePattern_movesToTheNextPattern() {
        XCTAssertEqual(slot(selected: 2, angle: -30), 3)
    }

    func test_slot_turningForwardOnePattern_movesToThePreviousPattern() {
        XCTAssertEqual(slot(selected: 2, angle: 30), 1)
    }

    func test_slot_changesHalfwayBetweenTwoPatterns() {
        XCTAssertEqual(slot(selected: 2, angle: -14), 2)
        XCTAssertEqual(slot(selected: 2, angle: -16), 3)
    }

    func test_slot_staysOnTheWheel() {
        XCTAssertEqual(slot(selected: 0, angle: 90), 0)
        XCTAssertEqual(slot(selected: 4, angle: -90), 4)
    }

    func test_slot_withNoPatterns_isZero() {
        XCTAssertEqual(slot(selected: 0, angle: -60, count: 0), 0)
    }

    // MARK: settleDelays

    func test_settleDelays_samePattern_hasNoTicks() {
        XCTAssertEqual(PatternWheelTicks.settleDelays(from: 2, to: 2, duration: 0.28), [])
    }

    func test_settleDelays_onePatternAway_ticksOnceAtOnce() {
        XCTAssertEqual(PatternWheelTicks.settleDelays(from: 1, to: 2, duration: 0.28), [0])
    }

    func test_settleDelays_ticksOncePerPatternPassed_spreadOverTheAnimation() {
        let delays = PatternWheelTicks.settleDelays(from: 4, to: 0, duration: 0.4)
        XCTAssertEqual(delays.count, 4)
        for (delay, expected) in zip(delays, [0, 0.1, 0.2, 0.3]) {
            XCTAssertEqual(delay, expected, accuracy: 1e-9)
        }
    }
}
