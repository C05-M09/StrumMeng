//
//  ReplayReducer.swift
//  StrumMeng
//
//  Created by Sharon Tan on 29/10/26.
//

import Foundation

/// Pure transition function for the Replay feature.
///
/// Maps `(state, event)` to a new `ReplayState`.
/// Has no side effects (no persistence, no I/O, no time dependency).
/// Illegal transitions are ignored, returning the original state unchanged.
func reduce(_ state: ReplayState, _ event: ReplayEvent) -> ReplayState {
    switch (state, event) {
    case (.ready, .play):
        return .playing

    case (.playing, .pause):
        return .paused

    case (.paused, .play), (.paused, .resume):
        return .playing

    case (.playing, .finish):
        return .finished

    case (.paused, .restart), (.finished, .restart), (.playing, .restart):
        return .playing

    case (.finished, .play):
        return .playing

    case (_, .backToSummary):
        return .dismissed

    default:
        return state
    }
}
