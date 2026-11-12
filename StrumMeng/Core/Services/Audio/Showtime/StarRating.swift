//
//  StarRating.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import Foundation

/// Pure policy determining star ratings (0 to 3) for a Showtime session from its accuracy.
enum StarRating {
    /// Returns the number of stars (0 to 3) earned for a given accuracy.
    ///
    /// - Parameters:
    ///   - accuracy: The session accuracy, either as a fraction `0.0...1.0` or percentage `0...100`.
    ///   - config: Threshold configuration. Defaults to `.default`.
    /// - Returns: An integer from 0 to 3 based on the configured thresholds.
    static func stars(
        for accuracy: Double,
        config: StarRatingConfig = .default
    ) -> Int {
        let percentage = accuracy <= 1.0 ? accuracy * 100.0 : accuracy

        if percentage <= config.zeroStarMaxPercentage {
            return 0
        } else if percentage <= config.oneStarMaxPercentage {
            return 1
        } else if percentage <= config.twoStarMaxPercentage {
            return 2
        } else {
            return 3
        }
    }
}

