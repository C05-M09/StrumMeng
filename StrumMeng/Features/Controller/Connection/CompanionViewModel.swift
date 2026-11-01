import Foundation
import Observation

/// Dummy iPhone flow: any six digits "connect" after a short wait, and swipes only move the pad's
/// arrow. Nothing is sent to the iPad yet.
@MainActor
@Observable
final class CompanionViewModel {
    /// Finger travel for one strum, in points.
    static let swipeThreshold: Double = 20

    private(set) var state: CompanionState
    private(set) var lastStrum: StrumDirection?
    /// Goes up on every strum, so the same direction twice still animates.
    private(set) var strumCount = 0

    private let connectDelay: Duration
    private var tracker = SwipeTracker()
    private var connectTask: Task<Void, Never>?

    init(state: CompanionState = .enteringCode(""), connectDelay: Duration = .seconds(1.2)) {
        self.state = state
        self.connectDelay = connectDelay
    }

    func send(_ event: CompanionEvent) {
        state = reduce(state, event)

        if case .connecting = state {
            startConnecting()
        } else {
            cancelConnecting()
        }
        if state != .connected {
            tracker.reset()
            lastStrum = nil
        }
    }

    /// The pad is held in portrait with the strings running up the screen, so strumming moves
    /// across them: right is a down strum, left is an up strum.
    func swipe(dx: Double) {
        guard state == .connected,
              let direction = tracker.feed(dx, threshold: Self.swipeThreshold) else { return }
        lastStrum = direction
        strumCount += 1
    }

    func endSwipe() {
        tracker.reset()
    }

    func stop() {
        cancelConnecting()
    }

    private func startConnecting() {
        guard connectTask == nil else { return }
        connectTask = Task { [weak self, connectDelay] in
            try? await Task.sleep(for: connectDelay)
            guard !Task.isCancelled else { return }
            self?.send(.linkConnected)
        }
    }

    private func cancelConnecting() {
        connectTask?.cancel()
        connectTask = nil
    }
}
