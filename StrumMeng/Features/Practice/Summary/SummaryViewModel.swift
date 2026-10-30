//
//  SummaryViewModel.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import Foundation
import Observation

/// View model driving the Summary screen.
///
/// Holds the current `SummaryState`, dispatches UI events through `reduce`,
/// and coordinates side effects such as saving the finished session record
/// to `SessionRepository` exactly once upon initial appearance.
@Observable
@MainActor
final class SummaryViewModel {
    private(set) var state: SummaryState
    let result: SessionResult
    private let repository: SessionRepository
    private(set) var hasSavedSession: Bool = false

    /// Where to go after Retry or Back to Main. Replay is shown inside SummaryView, so it is not sent.
    @ObservationIgnored private let onNavigate: (SummaryDestination) -> Void
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(
        result: SessionResult,
        repository: SessionRepository,
        onNavigate: @escaping (SummaryDestination) -> Void = { _ in }
    ) {
        self.result = result
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
    /// Leaving the screen waits for the save, so the practice list's records already include
    /// this session when they reload.
    func send(_ event: SummaryEvent) {
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
