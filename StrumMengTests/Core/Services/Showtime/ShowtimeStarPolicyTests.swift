//
//  ShowtimeStarPolicyTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import XCTest
@testable import StrumMeng

final class ShowtimeStarPolicyTests: XCTestCase {

    func test_accuracyAtOrBelowFiftyPercent_returnsZeroStars() {
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.0), 0)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.30), 0)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.50), 0)
    }

    func test_accuracyFiftyOneToSixtyFivePercent_returnsOneStar() {
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.51), 1)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.60), 1)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.65), 1)
    }

    func test_accuracySixtySixToEightyFivePercent_returnsTwoStars() {
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.66), 2)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.75), 2)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.85), 2)
    }

    func test_accuracyEightySixPercentOrAbove_returnsThreeStars() {
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.86), 3)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 0.95), 3)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 1.0), 3)
    }

    func test_accuracyPassedAsPercentage_isHandledCorrectly() {
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 45.0), 0)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 50.0), 0)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 55.0), 1)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 65.0), 1)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 70.0), 2)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 85.0), 2)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 90.0), 3)
        XCTAssertEqual(ShowtimeStarPolicy.stars(for: 100.0), 3)
    }
}

