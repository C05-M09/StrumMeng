import Foundation

/// The only way the app reads or writes saved sessions.
///
/// View models depend on this protocol, never on SwiftData. `AppContainer` is the one
/// place that wires in the real implementation.
nonisolated protocol SessionRepository: Sendable {
    /// Saves a finished session. Saving the same `id` again does nothing, so a Summary
    /// that appears twice can never create a duplicate record.
    func save(_ result: SessionResult) async throws

    /// Practice sessions for one pattern, best accuracy first. Ties go to the more
    /// recent session. Showtime sessions are excluded.
    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult]

    /// The BPM of the newest Practice session for this pattern, or `nil` if the user
    /// has never played it. Used as the starting BPM on the pattern card.
    func lastPracticeBPM(forPattern patternID: String) async throws -> Int?

    /// Records for one pattern, ordered by `sortedBy`. `limit == nil` returns all of them.
    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy: RecordSortCriterion
    ) async throws -> [SessionResult]
}
