import Foundation

/// Stands in when storage could not start, so Summary still works. Nothing is saved; the practice
/// list already shows its records error in that case.
struct UnavailableSessionRepository: SessionRepository {
    func save(_ result: SessionResult) async throws {}

    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] { [] }

    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? { nil }

    func topRecords(patternID: String, limit: Int?, sortedBy: RecordSortCriterion) async throws -> [SessionResult] {
        []
    }
}
