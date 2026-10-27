//
//  SummaryReducer.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation

/// Pure transition function for the Summary feature.
///
/// Maps `(state, event)` to a new `SummaryState`.
/// Has no side effects (no persistence, no I/O, no time dependency).
/// Illegal transitions are ignored, returning the original state unchanged.
func reduce(_ state: SummaryState, _ event: SummaryEvent) -> SummaryState {
    switch (state, event) {
    case (.showing(let result), .tapReplay):
        return .navigating(.replay(result))

    case (.showing(let result), .tapRetry):
        let recommendation = RecommendationPolicy.recommend(
            accuracy: result.accuracy,
            currentBPM: result.bpm
        )
        return .showingRecommendation(recommendation)

    case (.showing, .tapBackToMain):
        return .navigating(.backToMain)

    case (.showingRecommendation(let recommendation), .acceptRecommendation):
        return .navigating(.retry(bpm: recommendation.targetBPM))

    case (.showingRecommendation(let recommendation), .rejectRecommendation):
        return .navigating(.retry(bpm: recommendation.currentBPM))

    case (.showingRecommendation, .tapBackToMain):
        return .navigating(.backToMain)

    default:
        return state
    }
}
