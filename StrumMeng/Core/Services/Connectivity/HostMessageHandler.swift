import Foundation

/// What the iPad does with each message from the iPhone, without any networking, so it can be
/// unit-tested. Every transport (Bonjour, Wi-Fi Aware) feeds its messages through one of these.
nonisolated struct HostMessageHandler: Sendable {
    enum Output: Equatable, Sendable {
        case reply(ControllerMessage)
        case strum(StrumEvent)
        case ignore
    }

    /// The iPhone pings every second, so this much silence means it is gone.
    static let livenessTimeout: TimeInterval = 4.5

    /// Set by the link from setSessionActive. Strums outside a session are dropped.
    var sessionActive = false
    private(set) var controllerName: String?
    /// Latency the iPhone reported in its latest ping.
    private(set) var latencyMs: Double?
    private var lastHeard: TimeInterval?
    private var deduplicator = StrumDeduplicator()

    mutating func receive(_ message: ControllerMessage, arrivedAt arrival: TimeInterval) -> Output {
        lastHeard = arrival
        switch message {
        case let .hello(deviceName):
            controllerName = deviceName
            return .ignore
        case let .ping(sentAt, latencyMs):
            if let latencyMs { self.latencyMs = latencyMs }
            return .reply(.pong(sentAt: sentAt, receivedAt: arrival, sessionActive: sessionActive))
        case let .strum(id, direction, hostTime):
            // De-duplicate first, so the copies of a dropped strum are dropped too.
            guard deduplicator.isNew(id), sessionActive else { return .ignore }
            let time = StrumTimeResolver.hostTime(claimed: hostTime, arrivedAt: arrival)
            return .strum(StrumEvent(id: id, direction: direction, time: time))
        case .startSession, .stopSession, .pong:
            // iPad → iPhone messages; never expected here.
            return .ignore
        }
    }

    /// Call when a new connection becomes ready, so it counts as heard from even before its first ping.
    mutating func connectionOpened(at time: TimeInterval) {
        lastHeard = time
        latencyMs = nil
        controllerName = nil
    }

    func isAlive(now: TimeInterval) -> Bool {
        guard let lastHeard else { return false }
        return now - lastHeard < Self.livenessTimeout
    }
}
