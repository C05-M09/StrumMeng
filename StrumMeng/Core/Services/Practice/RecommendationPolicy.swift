//
//  RecommendationPolicy.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation

/// Pure policy determining tempo recommendations from session accuracy.
enum RecommendationPolicy {
    /// Produces a `RecommendedBPM` for a completed practice session.
    ///
    /// - Parameters:
    ///   - accuracy: The session accuracy, either as a fraction `0.0...1.0` or percentage `0...100`.
    ///   - currentBPM: The BPM of the completed practice session.
    ///   - config: Configuration bounding the recommended BPM. Defaults to 60...120.
    /// - Returns: A `RecommendedBPM` with target BPM clamped within the configured range.
    static func recommend(
        accuracy: Double,
        currentBPM: Int,
        config: RecommendationConfig = .default
    ) -> RecommendedBPM {
        let percentage = accuracy <= 1.0 ? accuracy * 100.0 : accuracy

        let delta: Int
        if percentage <= 50.0 {
            delta = -20
        } else if percentage <= 65.0 {
            delta = -10
        } else if percentage <= 85.0 {
            delta = 0
        } else {
            delta = 10
        }

        let unboundedTarget = currentBPM + delta
        let clampedTarget = min(config.maxBPM, max(config.minBPM, unboundedTarget))

        return RecommendedBPM(
            currentBPM: currentBPM,
            targetBPM: clampedTarget,
            accuracy: accuracy <= 1.0 ? accuracy : accuracy / 100.0,
            delta: delta
        )
    }
}

