import Foundation

/// The iPhone side of the controller link: finds the paired iPad, keeps the two clocks in sync
/// and sends strums while the iPad says a session is playing.
protocol ControllerClient: Sendable {
    /// Every subscriber first receives the current state, then each change.
    var connectionStates: AsyncStream<ControllerConnectionState> { get }
    /// Whether the iPad has a session playing. Every subscriber first receives the current value.
    var sessionActive: AsyncStream<Bool> { get }
    /// Starts looking for the iPad with this code and keeps reconnecting until disconnect().
    func connect(pairCode: PairCode) async
    /// Sends one strum. Dropped while no session is playing or no iPad is connected.
    /// - Parameter touchTime: when the finger crossed the threshold, on this iPhone's host clock.
    func send(_ direction: StrumDirection, touchTime: TimeInterval) async
    func disconnect() async
}
