//
//  ShowtimeSummaryState.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import Foundation

/// States of the Showtime Summary screen.
enum ShowtimeSummaryState: Equatable, Sendable {
    case showing(SessionResult)
    case navigating(ShowtimeSummaryDestination)
}

