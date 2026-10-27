//
//  SummaryDestination.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation

/// Navigation destinations reachable from the Summary screen.
enum SummaryDestination: Equatable, Sendable {
    case replay(SessionResult)
    case retry(bpm: Int)
    case backToMain
}
