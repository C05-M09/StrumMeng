import Foundation
@testable import StrumMeng

/// Test double for `SessionRepository`. It is an actor so it stays `Sendable` without
/// `@unchecked`; read its state from tests with `await`.
actor MockSessionRepository: SessionRepository {
    private(set) var savedResults: [SessionResult] = []
    private var stubbedRecords: [SessionResult] = []
    private var stubbedLastBPM: Int?

    func stub(records: [SessionResult], lastBPM: Int?) {
        stubbedRecords = records
        stubbedLastBPM = lastBPM
    }
    
    
    
    func save(_ result: SessionResult) async throws {
        guard !savedResults.contains(where: { $0.id == result.id }) else { return }
        savedResults.append(result)
    }

    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] {
        stubbedRecords
    }

    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? {
        stubbedLastBPM
    }

    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy: RecordSortCriterion
    ) async throws -> [SessionResult] {
        if let limit {
            return Array(stubbedRecords.prefix(limit))
        }
        return stubbedRecords
    }
}
