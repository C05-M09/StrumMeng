//
//  ShowtimeSummaryDestination.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import Foundation

/// Navigation destinations reachable from the Showtime Summary screen.
enum ShowtimeSummaryDestination: Equatable, Sendable {
    case replay(SessionResult)
    case retry
    case backToMain
}

