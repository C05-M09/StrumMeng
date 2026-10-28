import Foundation

/// Everything the iPhone controller and the iPad say to each other. Both transports (Wi-Fi Aware
/// and Bonjour) carry exactly these messages, so the rest of the link does not care which is up.
/// Nonisolated because it is encoded and decoded on the link's network queue.
nonisolated enum ControllerMessage: Codable, Sendable, Equatable {
    /// iPhone → iPad, once per connection, so the iPad can name the controller that joined.
    case hello(deviceName: String)
    /// iPad → iPhone. The iPhone sends strums only between startSession and stopSession.
    case startSession
    case stopSession
    /// iPhone → iPad. Sent several times over UDP; `id` lets the iPad drop the copies.
    /// `hostTime` is when the finger moved, already on the iPad host clock, or nil while the
    /// clocks are not synced yet (the iPad then falls back to the arrival time).
    case strum(id: UUID, direction: StrumDirection, hostTime: TimeInterval?)
    /// iPhone → iPad, carrying the iPhone clock when it was sent and the latency the iPhone
    /// measured so far, so the iPad can show it too.
    case ping(sentAt: TimeInterval, latencyMs: Double?)
    /// iPad → iPhone: echoes the ping time and adds when the ping arrived, on the iPad host clock.
    /// Also repeats whether a session is playing, so a lost startSession or stopSession packet
    /// corrects itself within one ping.
    case pong(sentAt: TimeInterval, receivedAt: TimeInterval, sessionActive: Bool)

    init(data: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
