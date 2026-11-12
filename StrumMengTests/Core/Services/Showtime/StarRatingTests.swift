//
//  StarRatingTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import XCTest
@testable import StrumMeng

final class StarRatingTests: XCTestCase {

    // MARK: - Boundary Values (Fractions 0.0...1.0)

    func test_accuracyZero_returnsZeroStars() {
        XCTAssertEqual(StarRating.stars(for: 0.0), 0)
    }

    func test_boundaryFiftyPercent_returnsZeroStars() {
        XCTAssertEqual(StarRating.stars(for: 0.50), 0)
    }

    func test_boundaryFiftyOnePercent_returnsOneStar() {
        XCTAssertEqual(StarRating.stars(for: 0.51), 1)
    }

    func test_boundarySixtyFivePercent_returnsOneStar() {
        XCTAssertEqual(StarRating.stars(for: 0.65), 1)
    }

    func test_boundarySixtySixPercent_returnsTwoStars() {
        XCTAssertEqual(StarRating.stars(for: 0.66), 2)
    }

    func test_boundaryEightyFivePercent_returnsTwoStars() {
        XCTAssertEqual(StarRating.stars(for: 0.85), 2)
    }

    func test_boundaryEightySixPercent_returnsThreeStars() {
        XCTAssertEqual(StarRating.stars(for: 0.86), 3)
    }

    func test_accuracyOneHundredPercent_returnsThreeStars() {
        XCTAssertEqual(StarRating.stars(for: 1.0), 3)
    }

    // MARK: - Boundary Values (Percentages 0...100)

    func test_percentageBoundaries_matchExpectedStars() {
        XCTAssertEqual(StarRating.stars(for: 0.0), 0)
        XCTAssertEqual(StarRating.stars(for: 50.0), 0)
        XCTAssertEqual(StarRating.stars(for: 51.0), 1)
        XCTAssertEqual(StarRating.stars(for: 65.0), 1)
        XCTAssertEqual(StarRating.stars(for: 66.0), 2)
        XCTAssertEqual(StarRating.stars(for: 85.0), 2)
        XCTAssertEqual(StarRating.stars(for: 86.0), 3)
        XCTAssertEqual(StarRating.stars(for: 100.0), 3)
    }

    // MARK: - Configuration Override

    func test_customConfig_overridesDefaultThresholds() {
        let custom = StarRatingConfig(
            zeroStarMaxPercentage: 40.0,
            oneStarMaxPercentage: 60.0,
            twoStarMaxPercentage: 80.0
        )

        XCTAssertEqual(StarRating.stars(for: 0.40, config: custom), 0)
        XCTAssertEqual(StarRating.stars(for: 0.45, config: custom), 1)
        XCTAssertEqual(StarRating.stars(for: 0.60, config: custom), 1)
        XCTAssertEqual(StarRating.stars(for: 0.65, config: custom), 2)
        XCTAssertEqual(StarRating.stars(for: 0.80, config: custom), 2)
        XCTAssertEqual(StarRating.stars(for: 0.81, config: custom), 3)
    }
}

