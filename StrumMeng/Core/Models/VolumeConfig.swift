//
//  VolumeConfig.swift
//  StrumMeng
//
//  Created by rasyel on 27/10/26.
//


import Foundation

/// Limits and default for the volume settings, in one place (like `PracticeTempoConfig`).
/// Volumes are fractions from 0 (silent) to 1 (full).
enum VolumeConfig {
    static let minimum = 0.0
    static let maximum = 1.0
    static let step = 0.1
    static let defaultVolume = 0.5

    static let range: ClosedRange<Double> = minimum...maximum

    /// Keeps a value inside the range. A value that is not a number falls back to the default.
    static func clamped(_ volume: Double) -> Double {
        guard volume.isFinite else { return defaultVolume }
        return min(max(volume, minimum), maximum)
    }
}
