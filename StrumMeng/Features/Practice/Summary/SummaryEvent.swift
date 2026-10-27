//
//  SummaryEvent.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation

/// Events accepted by the Summary state machine.
enum SummaryEvent: Equatable, Sendable {
    case tapReplay
    case tapRetry
    case tapBackToMain
    case acceptRecommendation
    case rejectRecommendation
}
