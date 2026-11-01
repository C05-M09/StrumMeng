import Foundation
import Observation

/// The iPhone side: pairs with the iPad through ControllerClient and sends each swipe as a strum.
@MainActor
@Observable
final class CompanionViewModel {
    /// Finger travel for one strum, in points, the same as on-screen swipes on the iPad.
    static let swipeThreshold: Double = 12
    /// The longest believable gap between a touch and its handling, as in PlayViewModel.
    private static let maxTouchDelay: TimeInterval = 0.1

    private(set) var state: CompanionState
    private(set) var lastStrum: StrumDirection?
    /// Goes up on every strum, so the same direction twice still animates.
    private(set) var strumCount = 0

    @ObservationIgnored private let client: any ControllerClient
    @ObservationIgnored private let pairCodes: any PairCodeStore
    @ObservationIgnored private let now: () -> TimeInterval
    @ObservationIgnored private let connectTimeout: Duration
    @ObservationIgnored private var tracker = SwipeTracker()
    @ObservationIgnored private var linkTask: Task<Void, Never>?
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?

    /// - Parameter connectTimeout: how long a typed code may look for the iPad. A saved code has no
    ///   limit: the iPad may simply not be open yet, and Cancel is there if it never comes.
    init(
        client: any ControllerClient,
        pairCodes: any PairCodeStore,
        state: CompanionState = .enteringCode(""),
        now: @escaping () -> TimeInterval = HostClock.now,
        connectTimeout: Duration = .seconds(10)
    ) {
        self.client = client
        self.pairCodes = pairCodes
        self.state = state
        self.now = now
        self.connectTimeout = connectTimeout
    }

    /// Follows the link and goes back to the iPad it was last paired with.
    func appear() {
        guard linkTask == nil else { return }
        linkTask = Task { [weak self, states = client.connectionStates] in
            for await linkState in states {
                self?.linkStateChanged(linkState)
            }
        }
        if let saved = pairCodes.enteredPairCode {
            send(.resumePairing(saved.value))
        }
    }

    /// The screen went away. Unlike Unpair, this keeps the saved code for the next launch.
    func stop() {
        linkTask?.cancel()
        linkTask = nil
        cancelTimeout()
        Task { [client] in await client.disconnect() }
    }

    func send(_ event: CompanionEvent) {
        let previous = state
        state = reduce(state, event)
        guard state != previous else { return }
        cancelTimeout()

        switch state {
        case let .connecting(text):
            if let code = PairCode(text) {
                Task { [client] in await client.connect(pairCode: code) }
            }
            if case .typeDigit = event { startTimeout() }
        case .connected:
            // Saved only now, so a code that never connected is not retried on the next launch.
            if case let .connecting(text) = previous {
                pairCodes.setEnteredPairCode(PairCode(text))
            }
        case .notFound:
            // The link would otherwise keep looking for an iPad with the wrong code.
            Task { [client] in await client.disconnect() }
        case .enteringCode, .reconnecting:
            tracker.reset()
        }

        if event == .disconnect {
            lastStrum = nil
            pairCodes.setEnteredPairCode(nil)
            Task { [client] in await client.disconnect() }
        }
    }

    /// The pad is held in portrait with the strings running up the screen, so strumming moves
    /// across them: right is a down strum, left is an up strum.
    /// - Parameter eventDate: the touch event's own timestamp, so the strum keeps its real time.
    func swipe(dx: Double, eventDate: Date = Date()) {
        guard state == .connected,
              let direction = tracker.feed(dx, threshold: Self.swipeThreshold) else { return }
        lastStrum = direction
        strumCount += 1
        let delay = Date().timeIntervalSince(eventDate)
        let usable = (0...Self.maxTouchDelay).contains(delay) ? delay : 0
        let touchTime = now() - usable
        Task { [client] in await client.send(direction, touchTime: touchTime) }
    }

    func endSwipe() {
        tracker.reset()
    }

    private func startTimeout() {
        timeoutTask = Task { [weak self, connectTimeout] in
            try? await Task.sleep(for: connectTimeout)
            guard !Task.isCancelled else { return }
            self?.send(.connectionTimedOut)
        }
    }

    private func cancelTimeout() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    private func linkStateChanged(_ linkState: ControllerConnectionState) {
        switch linkState {
        case .connected:
            send(.linkConnected)
        case .reconnecting:
            send(.linkLost)
        case .unpaired, .pairing, .searching:
            break
        }
    }
}
