import XCTest
@testable import StrumMeng

final class StrumTimeResolverTests: XCTestCase {
    func test_plausibleTouchTime_isUsedInsteadOfArrival() {
        XCTAssertEqual(StrumTimeResolver.hostTime(claimed: 99.97, arrivedAt: 100), 99.97)
    }

    func test_unsyncedStrum_fallsBackToArrival() {
        XCTAssertEqual(StrumTimeResolver.hostTime(claimed: nil, arrivedAt: 100), 100)
    }

    func test_touchFarBeforeArrival_meansABadOffset_soArrivalIsUsed() {
        XCTAssertEqual(StrumTimeResolver.hostTime(claimed: 99, arrivedAt: 100), 100)
    }

    func test_touchFarAfterArrival_meansABadOffset_soArrivalIsUsed() {
        XCTAssertEqual(StrumTimeResolver.hostTime(claimed: 100.5, arrivedAt: 100), 100)
    }

    func test_touchSlightlyAfterArrival_isClippedToArrival() {
        XCTAssertEqual(StrumTimeResolver.hostTime(claimed: 100.005, arrivedAt: 100), 100)
    }
}
