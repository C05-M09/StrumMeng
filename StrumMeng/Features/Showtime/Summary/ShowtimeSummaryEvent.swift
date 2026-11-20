//
//  ShowtimeSummaryEvent.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import Foundation

/// Events accepted by the Showtime Summary state machine.
enum ShowtimeSummaryEvent: Equatable, Sendable {
    case tapReplay
    case tapRetry
    case tapBackToMain
    case returnFromReplay
}

