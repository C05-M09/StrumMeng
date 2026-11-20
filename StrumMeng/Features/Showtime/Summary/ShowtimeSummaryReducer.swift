//
//  ShowtimeSummaryReducer.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import Foundation

/// Pure transition function for the Showtime Summary feature.
///
/// Maps `(state, event)` to a new `ShowtimeSummaryState`.
/// Has no side effects (no persistence, no I/O, no time dependency).
/// Illegal transitions are ignored, returning the original state unchanged.
func reduce(_ state: ShowtimeSummaryState, _ event: ShowtimeSummaryEvent) -> ShowtimeSummaryState {
    switch (state, event) {
    case (.showing(let result), .tapReplay):
        return .navigating(.replay(result))

    case (.showing, .tapRetry):
        return .navigating(.retry)

    case (.showing, .tapBackToMain):
        return .navigating(.backToMain)

    case (.navigating(.replay(let result)), .returnFromReplay):
        return .showing(result)

    default:
        return state
    }
}

