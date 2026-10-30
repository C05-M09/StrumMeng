import Foundation

/// What the iPhone does with each message from the iPad and how it builds its own, without any
/// networking, so it can be unit-tested. Every transport feeds its messages through one of these.
nonisolated struct ClientMessageHandler: Sendable {
    /// Each strum is sent this many times over UDP so one lost packet does not lose it.
    static let strumCopies = 3
    /// The iPad answers every ping, so this much silence means it is gone.
    static let livenessTimeout: TimeInterval = 4.5
    /// Pings sent quickly after connecting, so the clocks sync before the player starts.
    static let quickPingCount = 10

    private(set) var clock = ClockSync()
    private(set) var sessionActive = false
    private var lastHeard: TimeInterval?

    mutating func receive(_ message: ControllerMessage, arrivedAt arrival: TimeInterval) {
        lastHeard = arrival
        switch message {
        case let .pong(sentAt, receivedAt, sessionActive):
            clock.record(sentAt: sentAt, hostReceivedAt: receivedAt, receivedBackAt: arrival)
            // A pong reordered behind a start/stop can briefly undo it; the next pong fixes that.
            self.sessionActive = sessionActive
        case .startSession:
            sessionActive = true
        case .stopSession:
            sessionActive = false
        case .hello, .ping, .strum:
            // iPhone → iPad messages; never expected here.
            break
        }
    }

    /// The message for one strum, or nil while no session is playing.
    /// - Parameter touchTime: when the finger moved, on this iPhone's clock.
    func strumMessage(id: UUID, direction: StrumDirection, touchTime: TimeInterval) -> ControllerMessage? {
        guard sessionActive else { return nil }
        return .strum(id: id, direction: direction, hostTime: clock.hostTime(fromLocalTime: touchTime))
    }

    func pingMessage(sentAt: TimeInterval) -> ControllerMessage {
        .ping(sentAt: sentAt, latencyMs: clock.latencyMs)
    }

    /// Ping interval while a session is playing. Steady traffic keeps both Wi-Fi radios out of
    /// power save, which otherwise holds a strum for up to a beacon interval (~100 ms) after a
    /// quiet moment. It also keeps the clock samples fresh during play.
    static let playingPingInterval: Duration = .milliseconds(50)

    /// How long to wait after sending ping number `count` (1-based): fast while playing, otherwise
    /// quick at first and then every second to save battery.
    static func pingDelay(afterPing count: Int, sessionActive: Bool) -> Duration {
        if sessionActive { return playingPingInterval }
        return count < quickPingCount ? .milliseconds(150) : .seconds(1)
    }

    /// Call when a new connection becomes ready. Old clock samples and session state no longer apply.
    mutating func connectionOpened(at time: TimeInterval) {
        self = ClientMessageHandler()
        lastHeard = time
    }

    func isAlive(now: TimeInterval) -> Bool {
        guard let lastHeard else { return false }
        return now - lastHeard < Self.livenessTimeout
    }
}
