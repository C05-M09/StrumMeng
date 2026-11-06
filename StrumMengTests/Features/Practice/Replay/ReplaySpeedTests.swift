import XCTest
@testable import StrumMeng

final class ReplaySpeedTests: XCTestCase {
    func test_rates_matchTheirNames() {
        XCTAssertEqual(ReplaySpeed.half.rate, 0.5)
        XCTAssertEqual(ReplaySpeed.threeQuarters.rate, 0.75)
        XCTAssertEqual(ReplaySpeed.normal.rate, 1)
        XCTAssertEqual(ReplaySpeed.oneAndHalf.rate, 1.5)
    }

    func test_next_goesFromSlowToFast_andWrapsAround() {
        XCTAssertEqual(ReplaySpeed.half.next, .threeQuarters)
        XCTAssertEqual(ReplaySpeed.threeQuarters.next, .normal)
        XCTAssertEqual(ReplaySpeed.normal.next, .oneAndHalf)
        XCTAssertEqual(ReplaySpeed.oneAndHalf.next, .half)
    }

    func test_labels_areShortMultipliers() {
        XCTAssertEqual(ReplaySpeed.allCases.map(\.label), ["0.5×", "0.75×", "1×", "1.5×"])
    }
}
