import Foundation
import SwiftData

/// The Showtime side of the SwiftData repository. The Practice side stays in
/// `SwiftDataSessionRepository.swift`, unchanged.
extension SwiftDataSessionRepository: SongRecordsRepository {
    func records(forSong songID: String, sortedBy criterion: RecordSortCriterion) async throws -> [SessionResult] {
        let wantedSongID: String? = songID

        let sort: [SortDescriptor<PracticeSessionRecord>]
        switch criterion {
        case .accuracy:
            sort = [
                SortDescriptor(\.accuracy, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        case .mostRecent:
            sort = [SortDescriptor(\.createdAt, order: .reverse)]
        }

        let descriptor = FetchDescriptor<PracticeSessionRecord>(
            predicate: #Predicate<PracticeSessionRecord> { $0.songID == wantedSongID },
            sortBy: sort
        )
        return try modelContext.fetch(descriptor).map(SessionRecordMapper.makeResult(from:))
    }
}
