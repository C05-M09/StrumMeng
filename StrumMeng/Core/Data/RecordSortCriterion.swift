//
//  RecordSortCriterion.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

/// How `topRecords` orders its result.
enum RecordSortCriterion: Sendable, Equatable {
    /// Best accuracy first. Ties go to the more recent session.
    case accuracy
    /// Newest first.
    case mostRecent
}
