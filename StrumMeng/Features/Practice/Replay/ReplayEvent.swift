//
//  ReplayEvent.swift
//  StrumMeng
//
//  Created by Sharon Tan on 29/10/26.
//

import Foundation

/// Events driving the Replay state machine.
enum ReplayEvent: Equatable, Sendable {
    case play
    case pause
    case resume
    case restart
    case finish
    case backToSummary
    /// Jumps to a point on the progress bar (0 = first beat, 1 = the end). Does not change the state.
    case seek(progress: Double)
}
