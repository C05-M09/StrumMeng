//
//  RecordsViewModel.swift
//  StrumMeng
//
//  Created by rasyel on 26/10/26.
//

import Observation

/// Loads the records shown inside one pattern card.
/// Talks to the repository only through the `SessionRepository` protocol.
@MainActor
@Observable
final class RecordsViewModel {
    private(set) var state: RecordsViewState = .loading

    private let patternID: String
    private let repository: SessionRepository
    private let sortCriterion: RecordSortCriterion

    init(
        patternID: String,
        repository: SessionRepository,
        sortCriterion: RecordSortCriterion = .accuracy
    ) {
        self.patternID = patternID
        self.repository = repository
        self.sortCriterion = sortCriterion
    }

    /// Safe to call repeatedly (every time the list appears).
    /// It keeps the current rows on screen while reloading, so there is no flicker.
    func load() async {
        do {
            // limit nil = all records; the card shows 3 rows and scrolls the rest.
            let results = try await repository.topRecords(
                patternID: patternID,
                limit: nil,
                sortedBy: sortCriterion
            )
            guard !Task.isCancelled else { return }
            if results.isEmpty {
                state = .empty
            } else {
                state = .loaded(
                    results.enumerated().map { RecordRowModel(rank: $0.offset + 1, result: $0.element) }
                )
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed
        }
    }
}
