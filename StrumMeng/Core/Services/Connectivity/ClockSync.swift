import Foundation

/// Estimates how far the iPad host clock is ahead of the iPhone clock from ping/pong round trips,
/// the way NTP does. Runs on the iPhone, which converts each touch time to iPad host time before
/// sending it, so network delay never counts against the player.
nonisolated struct ClockSync: Equatable, Sendable {
    /// Recent samples kept; the fastest of them gives the offset.
    static let sampleLimit = 10
    /// Round trips slower than this were held up too long to say anything about the clocks.
    static let maxRoundTrip: TimeInterval = 2

    private struct Sample: Equatable, Sendable {
        let roundTrip: TimeInterval
        let offset: TimeInterval
    }

    private var samples: [Sample] = []

    /// iPad host time minus iPhone time, or nil before the first usable pong. Taken from the
    /// fastest recent round trip, because that one waited least in Wi-Fi queues.
    var offset: TimeInterval? {
        samples.min { $0.roundTrip < $1.roundTrip }?.offset
    }

    /// One-way delay of the latest round trip, in milliseconds, for the connection status.
    var latencyMs: Double? {
        samples.last.map { $0.roundTrip / 2 * 1000 }
    }

    /// - Parameters:
    ///   - sentAt: iPhone clock when the ping left.
    ///   - hostReceivedAt: iPad host clock when the ping arrived.
    ///   - receivedBackAt: iPhone clock when the pong arrived.
    mutating func record(sentAt: TimeInterval, hostReceivedAt: TimeInterval, receivedBackAt: TimeInterval) {
        let roundTrip = receivedBackAt - sentAt
        guard roundTrip >= 0, roundTrip < Self.maxRoundTrip else { return }
        let offset = hostReceivedAt - (sentAt + receivedBackAt) / 2
        samples = Array((samples + [Sample(roundTrip: roundTrip, offset: offset)]).suffix(Self.sampleLimit))
    }

    /// Forget all samples, for example after a reconnect, when the old round trips no longer apply.
    mutating func reset() {
        samples = []
    }

    /// Converts an iPhone clock time to iPad host time, or nil while not synced.
    func hostTime(fromLocalTime time: TimeInterval) -> TimeInterval? {
        offset.map { time + $0 }
    }
}
