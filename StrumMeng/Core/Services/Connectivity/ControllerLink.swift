import Foundation

/// The iPhone controller link (ARCHITECTURE.md §3.2.3). Both transports end up here as one
/// de-duplicated stream of strums on the iPad host clock. It refines StrumInputService so the
/// game loop can take it in place of on-screen swipes without changing.
protocol ControllerLink: StrumInputService {
    var connectionStates: AsyncStream<ControllerConnectionState> { get }
    var strums: AsyncStream<StrumEvent> { get }
    func start() async throws
    /// Re-publishes when the Wi-Fi Aware publish is old. Call before a count-in, never while playing.
    func refreshIfNeeded() async throws
    func stop() async
}
