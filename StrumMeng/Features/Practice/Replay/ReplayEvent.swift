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
    case restart
    case finish
    case backToSummary
}
