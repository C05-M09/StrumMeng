import Foundation
@testable import StrumMeng

/// A repository whose saves wait until the test calls `open()`, to check what happens while a save
/// is still in progress.
actor GatedSessionRepository: SessionRepository {
    private(set) var savedResults: [SessionResult] = []
    private var isOpen = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func open() {
        isOpen = true
        waiting.forEach { $0.resume() }
        waiting = []
    }

    func save(_ result: SessionResult) async throws {
        if !isOpen {
            await withCheckedContinuation { waiting.append($0) }
        }
        savedResults.append(result)
    }

    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] { [] }

    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? { nil }

    func topRecords(patternID: String, limit: Int?, sortedBy: RecordSortCriterion) async throws -> [SessionResult] {
        []
    }
}
