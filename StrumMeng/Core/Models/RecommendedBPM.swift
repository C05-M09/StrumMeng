//
//  RecommendedBPM.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation

/// Tempo recommendation produced after a practice session.
///
/// Contains the current BPM, the newly recommended target BPM (clamped between 60 and 120),
/// the session's accuracy, and the tempo delta (-20, -10, 0, or +10).
struct RecommendedBPM: Equatable, Sendable {
    let currentBPM: Int
    let targetBPM: Int
    let accuracy: Double
    let delta: Int
}

/// Alias matching the task description specification.
typealias Recommendation = RecommendedBPM

