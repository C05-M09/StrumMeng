//
//  GuidebookCatalog.swift
//  StrumMeng
//
//  Created by sharon on 30/10/26.
//

import Foundation

/// Static local catalog of Guidebook pages (US 5).
enum GuidebookCatalog {
    static let pages: [GuidebookPage] = [
        GuidebookPage(
            id: "counting-beats",
            title: "Counting Beats",
            body: "Learn how to count beats with 1 & 2 & 3 & 4 & rhythm.",
            backgroundAsset: "Guidebook_1",
            isInteractiveTempo: false
        ),
        GuidebookPage(
            id: "practice-tempo",
            title: "Practice Tempo",
            body: "Tap your foot, count out loud, and practice steady tempo at your preferred BPM.",
            backgroundAsset: "Guidebook_2",
            isInteractiveTempo: true
        )
//        GuidebookPage(
//            id: "how-to-strum",
//            title: "How to Strum",
//            body: "Tips for holding your pick or controller and strumming smoothly.",
//            backgroundAsset: "Guidebook_3",
//            isInteractiveTempo: false
//        )
    ]
}

