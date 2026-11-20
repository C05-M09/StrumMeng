import Foundation

/// The iPhone side of the controller link: finds the paired iPad, keeps the two clocks in sync
/// and sends strums while the iPad says a session is playing.
protocol ControllerClient: Sendable {
    /// Every subscriber first receives the current state, then each change.
    var connectionStates: AsyncStream<ControllerConnectionState> { get }
    /// Whether the iPad has a session playing. Every subscriber first receives the current value.
    var sessionActive: AsyncStream<Bool> { get }
    /// Whether the iPad left in the middle of a session (its app went to the background, or the
    /// link dropped while a session was playing) and is not back yet. Every subscriber first
    /// receives the current value.
    var hostLeftSession: AsyncStream<Bool> { get }
    /// Starts looking for the iPad with this code and keeps reconnecting until disconnect().
    func connect(pairCode: PairCode) async
    /// Sends one strum. Dropped while no session is playing or no iPad is connected.
    /// - Parameter touchTime: when the finger crossed the threshold, on this iPhone's host clock.
    func send(_ direction: StrumDirection, touchTime: TimeInterval) async
    func disconnect() async
    /// Tells the iPad this iPhone is leaving (the player tapped Unpair), then disconnects. Unlike
    /// disconnect(), the iPad goes straight back to showing the pair code.
    func unpair() async
    /// The iPhone app went to the background. Tells the iPad, which pauses a playing session at
    /// once, and stops pinging until returnFromBackground() so the iPad does not see it as back.
    func leaveForBackground() async
    /// The iPhone app is in front again: says hello and pings again, or reconnects if the iPad
    /// stopped answering meanwhile.
    func returnFromBackground() async
}
