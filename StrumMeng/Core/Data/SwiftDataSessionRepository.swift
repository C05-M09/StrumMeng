import Foundation
import SwiftData

/// SwiftData-backed `SessionRepository`.
///
/// `@ModelActor` gives this actor its own `ModelContext`, so every read and write is
/// confined to one executor. That keeps non-Sendable SwiftData state out of the rest
/// of the app without any `@unchecked Sendable`.
@ModelActor
actor SwiftDataSessionRepository: SessionRepository {
    func save(_ result: SessionResult) async throws {
        let id = result.id
        var existing = FetchDescriptor<PracticeSessionRecord>(
            predicate: #Predicate<PracticeSessionRecord> { $0.id == id }
        )
        existing.fetchLimit = 1

        guard try modelContext.fetch(existing).isEmpty else { return }

        modelContext.insert(try SessionRecordMapper.makeRecord(from: result))
        try modelContext.save()
    }

    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy criterion: RecordSortCriterion
    ) async throws -> [SessionResult] {
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

        var descriptor = FetchDescriptor<PracticeSessionRecord>(
            predicate: #Predicate<PracticeSessionRecord> {
                $0.patternID == patternID && $0.songID == nil
            },
            sortBy: sort
        )
        if let limit { descriptor.fetchLimit = limit }

        return try modelContext.fetch(descriptor).map(SessionRecordMapper.makeResult(from:))
    }

    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] {
        try await topRecords(patternID: patternID, limit: nil, sortedBy: .accuracy)
    }

    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? {
        var descriptor = FetchDescriptor<PracticeSessionRecord>(
            predicate: #Predicate<PracticeSessionRecord> {
                $0.patternID == patternID && $0.songID == nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.bpm
    }
}
