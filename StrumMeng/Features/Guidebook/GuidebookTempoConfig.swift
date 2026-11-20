//
//  GuidebookTempoConfig.swift
//  StrumMeng
//
//  Created by sharon on 30/10/26.
//

import Foundation

/// Tempo configuration and strum rhythm for the interactive Practice Tempo page (Guidebook Page 2).
enum GuidebookTempoConfig {
    static let minBPM = 60
    static let maxBPM = 120
    static let stepBPM = 5
    static let defaultBPM = 60

    /// 8-stroke alternate strum pattern (1 & 2 & 3 & 4 &) matching the Guidebook_Tempo asset.
    static let pattern = StrumPattern(
        id: "guidebook-tempo",
        name: "Practice Tempo",
        strokes: [.down, .up, .down, .up, .down, .up, .down, .up],
        beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
        beatsPerPattern: 4,
        suggestedOrder: 0,
        defaultBPM: defaultBPM
    )
}

