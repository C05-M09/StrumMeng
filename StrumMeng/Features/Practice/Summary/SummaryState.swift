//
//  SummaryState.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation

/// States of the Summary screen.
enum SummaryState: Equatable, Sendable {
    case showing(SessionResult)
    case showingRecommendation(RecommendedBPM)
    case navigating(SummaryDestination)
}
