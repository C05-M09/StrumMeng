//
//  RecommendationPolicyTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import XCTest
@testable import StrumMeng

final class RecommendationPolicyTests: XCTestCase {

    func test_accuracyAtOrBelowFiftyPercent_decreasesBPMByTwenty() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.50, currentBPM: 90)
        XCTAssertEqual(recommendation.delta, -20)
        XCTAssertEqual(recommendation.targetBPM, 70)
    }

    func test_accuracyFiftyOnePercent_decreasesBPMByTen() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.51, currentBPM: 90)
        XCTAssertEqual(recommendation.delta, -10)
        XCTAssertEqual(recommendation.targetBPM, 80)
    }

    func test_accuracySixtyFivePercent_decreasesBPMByTen() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.65, currentBPM: 90)
        XCTAssertEqual(recommendation.delta, -10)
        XCTAssertEqual(recommendation.targetBPM, 80)
    }

    func test_accuracySixtySixPercent_staysAtSameBPM() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.66, currentBPM: 90)
        XCTAssertEqual(recommendation.delta, 0)
        XCTAssertEqual(recommendation.targetBPM, 90)
    }

    func test_accuracyEightyFivePercent_staysAtSameBPM() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.85, currentBPM: 90)
        XCTAssertEqual(recommendation.delta, 0)
        XCTAssertEqual(recommendation.targetBPM, 90)
    }

    func test_accuracyEightySixPercent_increasesBPMByTen() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.86, currentBPM: 90)
        XCTAssertEqual(recommendation.delta, 10)
        XCTAssertEqual(recommendation.targetBPM, 100)
    }

    func test_accuracyOneHundredPercent_increasesBPMByTen() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 1.0, currentBPM: 80)
        XCTAssertEqual(recommendation.delta, 10)
        XCTAssertEqual(recommendation.targetBPM, 90)
    }

    func test_minimumBPMClamp_doesNotDropBelowSixty() {
        // 70 - 20 = 50, but clamped to min 60
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.40, currentBPM: 70)
        XCTAssertEqual(recommendation.targetBPM, 60)

        // 60 - 20 = 40, clamped to min 60
        let recommendationAtFloor = RecommendationPolicy.recommend(accuracy: 0.20, currentBPM: 60)
        XCTAssertEqual(recommendationAtFloor.targetBPM, 60)
    }

    func test_maximumBPMClamp_doesNotExceedOneHundredTwenty() {
        // 115 + 10 = 125, clamped to max 120
        let recommendation = RecommendationPolicy.recommend(accuracy: 0.95, currentBPM: 115)
        XCTAssertEqual(recommendation.targetBPM, 120)

        // 120 + 10 = 130, clamped to max 120
        let recommendationAtCeiling = RecommendationPolicy.recommend(accuracy: 0.90, currentBPM: 120)
        XCTAssertEqual(recommendationAtCeiling.targetBPM, 120)
    }

    func test_accuracyPassedAsPercentage_isHandledCorrectly() {
        let recommendation = RecommendationPolicy.recommend(accuracy: 88.0, currentBPM: 80)
        XCTAssertEqual(recommendation.delta, 10)
        XCTAssertEqual(recommendation.targetBPM, 90)
        XCTAssertEqual(recommendation.accuracy, 0.88, accuracy: 0.001)
    }
}
