//
//  RecommendationConfig.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation

/// Configuration values governing BPM recommendations.
struct RecommendationConfig: Equatable, Sendable {
    /// Minimum allowed BPM (clamped at 60).
    let minBPM: Int

    /// Maximum allowed BPM (clamped at 120).
    let maxBPM: Int

    /// Default configuration for StrumMeng practice.
    static let `default` = RecommendationConfig(
        minBPM: 60,
        maxBPM: 120
    )
}
