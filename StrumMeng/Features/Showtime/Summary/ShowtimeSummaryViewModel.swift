//
//  ShowtimeSummaryViewModel.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import Foundation
import Observation

/// View model driving the Showtime Summary screen.
///
/// Holds the current `ShowtimeSummaryState`, computes star ratings via `StarRating`,
/// dispatches UI events through `reduce`, and coordinates side effects such as saving
/// the finished session record to `SessionRepository` exactly once upon initial appearance.
@Observable
@MainActor
final class ShowtimeSummaryViewModel {
    private(set) var state: ShowtimeSummaryState
    let result: SessionResult
    let stars: Int
    private let repository: SessionRepository
    private(set) var hasSavedSession: Bool = false

    /// Where to go after Retry or Back to Main. Replay is shown inside ShowtimeSummaryView, so it is not sent.
    @ObservationIgnored private let onNavigate: (ShowtimeSummaryDestination) -> Void
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(
        result: SessionResult,
        repository: SessionRepository,
        onNavigate: @escaping (ShowtimeSummaryDestination) -> Void = { _ in }
    ) {
        self.result = result
        self.stars = StarRating.stars(for: result.accuracy)
        self.repository = repository
        self.onNavigate = onNavigate
        self.state = .showing(result)
    }

    /// Called when the summary screen appears.
    ///
    /// Saves the session to `SessionRepository` exactly once. Re-appearance of the
    /// view (e.g. returning from Replay) is ignored to prevent duplicate persistence.
    func onAppear() async {
        await save().value
    }

    /// Sends a user interaction event to transition the state machine.
    ///
    /// Leaving the screen waits for the save, so persistent storage already includes
    /// this session when any subsequent screen reloads.
    func send(_ event: ShowtimeSummaryEvent) {
        let previous = state
        state = reduce(state, event)
        guard state != previous, case let .navigating(destination) = state else { return }
        switch destination {
        case .replay:
            break
        case .retry, .backToMain:
            let pendingSave = save()
            Task { [onNavigate] in
                await pendingSave.value
                onNavigate(destination)
            }
        }
    }

    /// The one save of this session, started on first use and shared by every caller after that.
    @discardableResult
    private func save() -> Task<Void, Never> {
        if let saveTask { return saveTask }
        hasSavedSession = true
        let task = Task { [repository, result] in
            do {
                try await repository.save(result)
            } catch {
                // Persistence errors should not crash the UI.
            }
        }
        saveTask = task
        return task
    }
}

