import Foundation

/// Finished sessions on their way to the Summary screen. Routes carry only the session id (no large
/// objects across screens), so the result itself waits here until Summary asks for it.
///
/// Lives for the whole app session; a few results in memory cost nothing. Saving to disk is
/// SummaryViewModel's job, not this store's.
@MainActor
final class SessionResultStore {
    private var results: [UUID: SessionResult] = [:]

    func add(_ result: SessionResult) {
        results[result.id] = result
    }

    func result(for id: UUID) -> SessionResult? {
        results[id]
    }
}
