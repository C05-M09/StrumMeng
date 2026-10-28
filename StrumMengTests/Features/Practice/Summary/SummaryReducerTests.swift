//
//  SummaryReducerTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import XCTest
@testable import StrumMeng

final class SummaryReducerTests: XCTestCase {

    private func makeSampleResult(accuracy: Double = 0.90, bpm: Int = 80) -> SessionResult {
        SessionResult(
            id: UUID(),
            patternID: "foundation",
            songID: nil,
            bpm: bpm,
            accuracy: accuracy,
            perfectCount: 18,
            tooEarlyCount: 2,
            missCount: 0,
            createdAt: Date(),
            beatEvents: []
        )
    }

    func test_tapReplay_fromShowing_transitionsToNavigatingReplay() {
        let result = makeSampleResult()
        let initial = SummaryState.showing(result)

        let next = reduce(initial, .tapReplay)

        XCTAssertEqual(next, .navigating(.replay(result)))
    }

    func test_tapRetry_fromShowing_transitionsToShowingRecommendation() {
        let result = makeSampleResult(accuracy: 0.90, bpm: 80)
        let initial = SummaryState.showing(result)

        let next = reduce(initial, .tapRetry)

        let expectedRecommendation = RecommendationPolicy.recommend(accuracy: 0.90, currentBPM: 80)
        XCTAssertEqual(next, .showingRecommendation(expectedRecommendation))
    }

    func test_tapBackToMain_fromShowing_transitionsToNavigatingBackToMain() {
        let result = makeSampleResult()
        let initial = SummaryState.showing(result)

        let next = reduce(initial, .tapBackToMain)

        XCTAssertEqual(next, .navigating(.backToMain))
    }

    func test_acceptRecommendation_fromShowingRecommendation_navigatesToRetryWithTargetBPM() {
        let recommendation = RecommendedBPM(currentBPM: 80, targetBPM: 90, accuracy: 0.90, delta: 10)
        let initial = SummaryState.showingRecommendation(recommendation)

        let next = reduce(initial, .acceptRecommendation)

        XCTAssertEqual(next, .navigating(.retry(bpm: 90)))
    }

    func test_rejectRecommendation_fromShowingRecommendation_navigatesToRetryWithCurrentBPM() {
        let recommendation = RecommendedBPM(currentBPM: 80, targetBPM: 90, accuracy: 0.90, delta: 10)
        let initial = SummaryState.showingRecommendation(recommendation)

        let next = reduce(initial, .rejectRecommendation)

        XCTAssertEqual(next, .navigating(.retry(bpm: 80)))
    }

    func test_tapBackToMain_fromShowingRecommendation_transitionsToNavigatingBackToMain() {
        let recommendation = RecommendedBPM(currentBPM: 80, targetBPM: 90, accuracy: 0.90, delta: 10)
        let initial = SummaryState.showingRecommendation(recommendation)

        let next = reduce(initial, .tapBackToMain)

        XCTAssertEqual(next, .navigating(.backToMain))
    }

    func test_illegalTransitions_leaveStateUnchanged() {
        let result = makeSampleResult()
        let showing = SummaryState.showing(result)

        // Events intended for showingRecommendation should be ignored while showing
        XCTAssertEqual(reduce(showing, .acceptRecommendation), showing)
        XCTAssertEqual(reduce(showing, .rejectRecommendation), showing)

        // Events intended for showing should be ignored while navigating
        let navigating = SummaryState.navigating(.backToMain)
        XCTAssertEqual(reduce(navigating, .tapRetry), navigating)
        XCTAssertEqual(reduce(navigating, .tapReplay), navigating)
        XCTAssertEqual(reduce(navigating, .acceptRecommendation), navigating)
    }
}
