import Foundation
import Observation

/// Runs only on the host's Home screen; the iPhone keeps its existing pairing flow.
@MainActor
@Observable
final class PairingIntroductionViewModel {
    static let appearanceDelay: Duration = .milliseconds(1500)

    private(set) var state: PairingIntroductionState
    @ObservationIgnored private let store: any PairingIntroductionStore
    @ObservationIgnored private let onSetupRequested: () -> Void
    @ObservationIgnored private let wait: (Duration) async throws -> Void
    @ObservationIgnored private var presentationTask: Task<Void, Never>?

    init(store: any PairingIntroductionStore,
         state: PairingIntroductionState = .idle,
         wait: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
         onSetupRequested: @escaping () -> Void) {
        self.store = store
        self.state = state
        self.wait = wait
        self.onSetupRequested = onSetupRequested
    }

    /// Navigation, Home overlays and backgrounding cancel the pending presentation synchronously.
    func setActive(_ active: Bool) {
        guard active else {
            presentationTask?.cancel()
            presentationTask = nil
            send(.cancel)
            return
        }
        guard state == .idle else { return }
        guard !store.hasShownIntroduction else { send(.skip); return }
        send(.begin)
        presentationTask = Task { [weak self, wait] in
            do {
                try await wait(Self.appearanceDelay)
                try Task.checkCancellation()
                self?.send(.delayElapsed)
            } catch {
                // Cancellation is handled by setActive(false); stale tasks cannot reset a new run.
            }
        }
    }

    func send(_ event: PairingIntroductionEvent) {
        let previous = state
        state = reduce(state, event)
        if case .continueToSetup = event, previous == .welcoming, state == .finished {
            presentationTask?.cancel()
            presentationTask = nil
            store.markIntroductionShown()
            onSetupRequested()
        }
    }
}
