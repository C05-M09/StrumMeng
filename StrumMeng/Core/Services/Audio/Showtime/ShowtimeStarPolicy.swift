//
//  ShowtimeStarPolicy.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import Foundation

/// Pure policy determining star ratings for a Showtime session from its accuracy.
enum ShowtimeStarPolicy {
    /// Returns the number of stars (0 to 3) earned for a given accuracy.
    ///
    /// - Parameter accuracy: The session accuracy, either as a fraction `0.0...1.0` or percentage `0...100`.
    /// - Returns: An integer from 0 to 3 based on confirmed thresholds:
    ///   - 0 – 50%  -> 0 stars
    ///   - 51 – 65% -> 1 star
    ///   - 66 – 85% -> 2 stars
    ///   - 86 – 100% -> 3 stars
    static func stars(for accuracy: Double) -> Int {
        let percentage = accuracy <= 1.0 ? accuracy * 100.0 : accuracy

        if percentage <= 50.0 {
            return 0
        } else if percentage <= 65.0 {
            return 1
        } else if percentage <= 85.0 {
            return 2
        } else {
            return 3
        }
    }
}

