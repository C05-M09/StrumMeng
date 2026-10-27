//
//  RecordRowModel.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

import Foundation
 
/// Display model for one row in the Records list.
/// Views only see this, never `SessionResult` directly, so a change to the
/// contract only touches this mapper.
struct RecordRowModel: Identifiable, Equatable, Sendable {
    let id: UUID
    let rank: Int
    let accuracyPercent: Int
    let bpm: Int
    let perfectCount: Int
    let tooEarlyCount: Int
    let missCount: Int
 
    /// `rank` is 1-based and is decided by the order the repository returns.
    init(rank: Int, result: SessionResult) {
        self.id = result.id
        self.rank = rank
        // [Assumption] SessionResult.accuracy is 0...1. Change here if it is already 0...100.
        self.accuracyPercent = Int((result.accuracy * 100).rounded())
        self.bpm = result.bpm
        self.perfectCount = result.perfectCount
        self.tooEarlyCount = result.tooEarlyCount
        self.missCount = result.missCount
    }
}
