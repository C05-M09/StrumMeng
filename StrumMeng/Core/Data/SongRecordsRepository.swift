import Foundation

/// How Showtime reads the saved records of a song.
///
/// It is its own protocol, apart from `SessionRepository`, so the Practice code (its protocol, its
/// mock and `UnavailableSessionRepository`) stays exactly as it was. `SwiftDataSessionRepository`
/// adopts both.
nonisolated protocol SongRecordsRepository: Sendable {
    /// Every Showtime record of one song, ordered by `sortedBy` (best accuracy first, ties to the
    /// more recent session). Practice sessions are never included: they have no `songID`.
    func records(forSong songID: String, sortedBy: RecordSortCriterion) async throws -> [SessionResult]
}
