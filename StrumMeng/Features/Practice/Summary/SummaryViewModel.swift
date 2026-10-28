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

    init(result: SessionResult, repository: SessionRepository) {
        self.result = result
        self.repository = repository
        self.state = .showing(result)
    }

    /// Called when the summary screen appears.
    ///
    /// Saves the session to `SessionRepository` exactly once. Re-appearance of the
    /// view (e.g. returning from Replay) is ignored to prevent duplicate persistence.
    func onAppear() async {
        guard !hasSavedSession else { return }
        hasSavedSession = true
        do {
            try await repository.save(result)
        } catch {
            // Persistence errors should not crash the UI.
        }
    }

    /// Sends a user interaction event to transition the state machine.
    func send(_ event: SummaryEvent) {
        state = reduce(state, event)
    }
}
