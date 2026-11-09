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
    @ObservationIgnored private let makeGuitar: () -> (any GuitarSound)?
    @ObservationIgnored private var guitar: (any GuitarSound)?
    /// While the iPad has a session playing the sound comes from the iPad, so this iPhone stays silent.
    @ObservationIgnored private var isSessionActive = false
    @ObservationIgnored private var tracker = SwipeTracker()
    @ObservationIgnored private var linkTask: Task<Void, Never>?
    @ObservationIgnored private var sessionTask: Task<Void, Never>?
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?

    /// - Parameters:
    ///   - connectTimeout: how long a typed code may look for the iPad. A saved code has no limit:
    ///     the iPad may simply not be open yet, and Cancel is there if it never comes.
    ///   - makeGuitar: called once on appear, not here: this view model can be made again on a
    ///     redraw, and each real guitar starts its own audio engine.
    init(
        client: any ControllerClient,
        pairCodes: any PairCodeStore,
        state: CompanionState = .enteringCode(""),
        now: @escaping () -> TimeInterval = HostClock.now,
        connectTimeout: Duration = .seconds(10),
        makeGuitar: @escaping () -> (any GuitarSound)? = { nil }
    ) {
        self.client = client
        self.pairCodes = pairCodes
        self.state = state
        self.now = now
        self.connectTimeout = connectTimeout
        self.makeGuitar = makeGuitar
    }

    /// Follows the link and goes back to the iPad it was last paired with.
    func appear() {
        guard linkTask == nil else { return }
        linkTask = Task { [weak self, states = client.connectionStates] in
            for await linkState in states {
                self?.linkStateChanged(linkState)
            }
        }
        sessionTask = Task { [weak self, sessions = client.sessionActive] in
            for await active in sessions {
                self?.sessionChanged(active)
            }
        }
        if guitar == nil, let made = makeGuitar() {
            guitar = made
            Task { await made.prepare() }
        }
        if let saved = pairCodes.enteredPairCode {
            send(.resumePairing(saved.value))
        }
    }

    /// The screen went away. Unlike Unpair, this keeps the saved code for the next launch.
    func stop() {
        linkTask?.cancel()
        linkTask = nil
        sessionTask?.cancel()
        sessionTask = nil
        cancelTimeout()
        guitar?.stopStrums()
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
            if event == .confirmCode { startTimeout() }
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
    /// - Parameter touchAge: how long ago the touch event happened, so the strum keeps its real time.
    func swipe(dx: Double, touchAge: TimeInterval = 0) {
        guard state == .connected || state == .reconnecting,
              let direction = tracker.feed(dx, threshold: Self.swipeThreshold) else { return }
        lastStrum = direction
        strumCount += 1
        if !isSessionActive {
            guitar?.strum(direction, at: nil, accent: 1)
        }
        guard state == .connected else { return }
        let usable = (0...Self.maxTouchDelay).contains(touchAge) ? touchAge : 0
        let touchTime = now() - usable
        Task { [client] in await client.send(direction, touchTime: touchTime) }
    }

    func endSwipe() {
        tracker.reset()
    }

    private func sessionChanged(_ active: Bool) {
        isSessionActive = active
        // Cuts any strum still ringing here, so it does not sound over the iPad's count-in.
        if active { guitar?.stopStrums() }
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
