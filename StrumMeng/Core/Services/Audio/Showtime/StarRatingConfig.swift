//
//  StarRatingConfig.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import Foundation

/// Configuration values governing Showtime star rating accuracy thresholds.
struct StarRatingConfig: Equatable, Sendable {
    /// Maximum accuracy percentage (0...100) that yields 0 stars.
    let zeroStarMaxPercentage: Double

    /// Maximum accuracy percentage (0...100) that yields 1 star.
    let oneStarMaxPercentage: Double

    /// Maximum accuracy percentage (0...100) that yields 2 stars.
    let twoStarMaxPercentage: Double

    /// Default thresholds for StrumMeng Showtime:
    /// - 0 – 50%   -> 0 stars
    /// - 51 – 65%  -> 1 star
    /// - 66 – 85%  -> 2 stars
    /// - 86 – 100% -> 3 stars
    static let `default` = StarRatingConfig(
        zeroStarMaxPercentage: 50.0,
        oneStarMaxPercentage: 65.0,
        twoStarMaxPercentage: 85.0
    )
}

