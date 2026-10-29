//
//  RecordsViewModelTests.swift
//  StrumMeng
//
//  Created by rasyel on 28/10/26.
//

import XCTest
@testable import StrumMeng

/// Repository yang merekam panggilan, bisa melempar error, dan bisa "ditahan"
/// di tengah panggilan. Dipakai untuk skenario yang tidak bisa dilakukan MockSessionRepository.
private actor ControllableSessionRepository: SessionRepository {
    enum Behavior {
        case records([SessionResult])
        case failure(Error)
    }

    private var behavior: Behavior = .records([])
    private var suspendsCalls = false
    private var continuation: CheckedContinuation<Void, Never>?

    /// Setiap panggilan `topRecords`, supaya test bisa mengecek apa yang diminta view model.
    private(set) var calls: [(patternID: String, limit: Int?, sortedBy: RecordSortCriterion)] = []
    var callCount: Int { calls.count }

    func set(_ behavior: Behavior) { self.behavior = behavior }
    func setSuspending(_ value: Bool) { suspendsCalls = value }

    /// Melanjutkan topRecords yang sedang ditahan.
    func resume() {
        continuation?.resume()
        continuation = nil
    }

    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy: RecordSortCriterion
    ) async throws -> [SessionResult] {
        calls.append((patternID: patternID, limit: limit, sortedBy: sortedBy))
        let current = behavior          // diambil saat dipanggil, sebelum ditahan
        if suspendsCalls {
            await withCheckedContinuation { continuation = $0 }
        }
        switch current {
        case .records(let records): return records
        case .failure(let error): throw error
        }
    }

    // Method lain di protocol, tidak dipakai di test ini
    func save(_ result: SessionResult) async throws {}
    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] { [] }
    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? { nil }
}

// MARK: - Tests

@MainActor
final class RecordsViewModelTests: XCTestCase {

    // MARK: Helpers

    // SESUAIKAN: kalau tipe songID bukan String, atau accuracy memakai skala persen (0...100)
    // dan bukan 0...1, ubah di sini.
    private func makeResult(accuracy: Double = 0.9, index: Int = 0) -> SessionResult {
        SessionResult(
            id: UUID(),
            patternID: "p1",
            songID: "song-1",
            bpm: 100,
            accuracy: accuracy,
            perfectCount: 0,
            tooEarlyCount: 0,
            missCount: 0,
            createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
            beatEvents: []
        )
    }

    /// Hasil dengan akurasi menurun (1.0, 0.9, 0.8, ...), seperti urutan "terbaik ke terburuk".
    private func makeResults(count: Int) -> [SessionResult] {
        (0..<count).map { makeResult(accuracy: 1.0 - Double($0) * 0.1, index: $0) }
    }

    private func loadedRows(
        _ state: RecordsViewState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [RecordRowModel]? {
        if case .loaded(let rows) = state { return rows }
        XCTFail("State seharusnya .loaded, tapi \(state)", file: file, line: line)
        return nil
    }

    private func waitUntilCalled(_ repository: ControllableSessionRepository, times: Int = 1) async {
        for _ in 0..<200 {
            if await repository.callCount >= times { return }
            await Task.yield()
        }
        XCTFail("Repository tidak dipanggil \(times)x")
    }

    // MARK: - Initial state

    func test_init_stateIsLoading() async {
        let repository = ControllableSessionRepository()
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        guard case .loading = sut.state else {
            return XCTFail("State awal seharusnya .loading, tapi \(sut.state)")
        }
        let count = await repository.callCount
        XCTAssertEqual(count, 0, "init tidak boleh langsung memanggil repository")
    }

    // MARK: - Empty

    func test_load_withNoRecords_setsEmptyState() async {
        let repository = MockSessionRepository()
        await repository.stub(records: [], lastBPM: nil)
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        guard case .empty = sut.state else {
            return XCTFail("State seharusnya .empty, tapi \(sut.state)")
        }
    }

    // MARK: - Loaded

    func test_load_withRecords_setsLoadedStateWithAllRows() async {
        let repository = MockSessionRepository()
        await repository.stub(records: makeResults(count: 5), lastBPM: nil)
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        guard let rows = loadedRows(sut.state) else { return }
        XCTAssertEqual(rows.count, 5, "Semua record dimuat (limit nil), bukan hanya 3")
    }

    func test_load_assignsRanksStartingFromOneInOrder() async {
        let repository = MockSessionRepository()
        await repository.stub(records: makeResults(count: 4), lastBPM: nil)
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        guard let rows = loadedRows(sut.state) else { return }
        XCTAssertEqual(rows.map(\.rank), [1, 2, 3, 4])
    }

    func test_load_withSingleRecord_hasRankOne() async {
        let repository = MockSessionRepository()
        await repository.stub(records: makeResults(count: 1), lastBPM: nil)
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        XCTAssertEqual(loadedRows(sut.state)?.map(\.rank), [1])
    }

    // MARK: - Parameter ke repository

    func test_load_passesPatternIDToRepository() async {
        let repository = ControllableSessionRepository()
        let sut = RecordsViewModel(patternID: "pattern-xyz", repository: repository)

        await sut.load()

        let calls = await repository.calls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.patternID, "pattern-xyz")
    }

    func test_load_requestsAllRecordsWithNilLimit() async {
        let repository = ControllableSessionRepository()
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        let calls = await repository.calls
        XCTAssertEqual(calls.count, 1)
        XCTAssertNil(calls[0].limit, "Kartu menampilkan 3 baris dan scroll sisanya, jadi limit harus nil")
    }

    func test_load_usesAccuracyAsDefaultSortCriterion() async {
        let repository = ControllableSessionRepository()
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        let calls = await repository.calls
        XCTAssertEqual(calls.first?.sortedBy, .accuracy)
    }

    func test_load_usesInjectedSortCriterion() async {
        let repository = ControllableSessionRepository()
        let sut = RecordsViewModel(patternID: "p1", repository: repository, sortCriterion: .mostRecent)

        await sut.load()

        let calls = await repository.calls
        XCTAssertEqual(calls.first?.sortedBy, .mostRecent)
    }

    // MARK: - Error

    func test_load_whenRepositoryThrows_setsFailedState() async {
        struct DummyError: Error {}
        let repository = ControllableSessionRepository()
        await repository.set(.failure(DummyError()))
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        guard case .failed = sut.state else {
            return XCTFail("State seharusnya .failed, tapi \(sut.state)")
        }
    }

    func test_load_whenRepositoryThrowsCancellationError_doesNotChangeState() async {
        let repository = ControllableSessionRepository()
        await repository.set(.failure(CancellationError()))
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        await sut.load()

        guard case .loading = sut.state else {
            return XCTFail("CancellationError tidak boleh mengubah state, tapi \(sut.state)")
        }
    }

    // MARK: - Cancellation

    func test_load_whenTaskCancelledBeforeResultsReturn_doesNotUpdateState() async {
        let repository = ControllableSessionRepository()
        await repository.set(.records(makeResults(count: 3)))
        await repository.setSuspending(true)
        let sut = RecordsViewModel(patternID: "p1", repository: repository)

        let task = Task { await sut.load() }
        await waitUntilCalled(repository)
        task.cancel()
        await repository.resume()
        await task.value

        guard case .loading = sut.state else {
            return XCTFail("Hasil dari task yang dibatalkan harus diabaikan, tapi \(sut.state)")
        }
    }

    // MARK: - Reload (dipanggil setiap list muncul)

    func test_reload_keepsCurrentRowsWhileLoading_noFlicker() async {
        let repository = ControllableSessionRepository()
        await repository.set(.records(makeResults(count: 2)))
        let sut = RecordsViewModel(patternID: "p1", repository: repository)
        await sut.load()
        XCTAssertEqual(loadedRows(sut.state)?.count, 2)

        // Reload kedua ditahan di tengah jalan
        await repository.set(.records(makeResults(count: 3)))
        await repository.setSuspending(true)
        let task = Task { await sut.load() }
        await waitUntilCalled(repository, times: 2)

        XCTAssertEqual(loadedRows(sut.state)?.count, 2, "Baris lama tetap tampil selama reload")

        await repository.resume()
        await task.value

        XCTAssertEqual(loadedRows(sut.state)?.count, 3, "Setelah reload selesai, baris diperbarui")
    }

    func test_reload_afterNewSession_reflectsUpdatedRecords() async {
        let repository = MockSessionRepository()
        await repository.stub(records: [], lastBPM: nil)
        let sut = RecordsViewModel(patternID: "p1", repository: repository)
        await sut.load()
        guard case .empty = sut.state else { return XCTFail("Seharusnya .empty dulu") }

        // Simulasi: user selesai main, lalu kembali dari summary
        await repository.stub(records: makeResults(count: 1), lastBPM: nil)
        await sut.load()

        XCTAssertEqual(loadedRows(sut.state)?.map(\.rank), [1])
    }

    func test_reload_whenResultsBecomeEmpty_setsEmptyState() async {
        let repository = MockSessionRepository()
        await repository.stub(records: makeResults(count: 2), lastBPM: nil)
        let sut = RecordsViewModel(patternID: "p1", repository: repository)
        await sut.load()

        await repository.stub(records: [], lastBPM: nil)
        await sut.load()

        guard case .empty = sut.state else {
            return XCTFail("State seharusnya .empty, tapi \(sut.state)")
        }
    }

    func test_reload_whenRepositoryThrowsAfterLoaded_setsFailedState() async {
        struct DummyError: Error {}
        let repository = ControllableSessionRepository()
        await repository.set(.records(makeResults(count: 2)))
        let sut = RecordsViewModel(patternID: "p1", repository: repository)
        await sut.load()

        await repository.set(.failure(DummyError()))
        await sut.load()

        guard case .failed = sut.state else {
            return XCTFail("State seharusnya .failed, tapi \(sut.state)")
        }
    }
}
