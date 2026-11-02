//
//  GuidebookPage.swift
//  StrumMeng
//
//  Created by sharon on 30/10/26.
//

import Foundation

/// Represents a single page in the Guidebook.
/// Kept outside SwiftUI views so page content and assets can be changed without touching UI code.
struct GuidebookPage: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let body: String
    let backgroundAsset: String
    let isInteractiveTempo: Bool

    init(
        id: String,
        title: String,
        body: String = "",
        backgroundAsset: String,
        isInteractiveTempo: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.backgroundAsset = backgroundAsset
        self.isInteractiveTempo = isInteractiveTempo
    }
}

