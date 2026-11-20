import Foundation

/// The iPad side of the iPhone controller link (ARCHITECTURE.md §3.2.3). Every transport ends up
/// here as one de-duplicated stream of strums on the iPad host clock. It refines StrumInputService
/// so the game loop can take it in place of on-screen swipes without changing.
protocol ControllerLink: StrumInputService {
    /// Every subscriber first receives the current state, then each change.
    var connectionStates: AsyncStream<ControllerConnectionState> { get }
    var strums: AsyncStream<StrumEvent> { get }
    /// The code the player enters once on the iPhone to pair over regular Wi-Fi.
    var pairCode: PairCode { get }
    func start() async throws
    /// Re-publishes when the Wi-Fi Aware publish is old. Call before a count-in, never while playing.
    func refreshIfNeeded() async throws
    /// Tells the iPhone whether a session is playing. The iPhone sends strums only while it is,
    /// and the link drops any strum that arrives outside a session.
    func setSessionActive(_ active: Bool) async
    /// The iPad app is leaving for the background in the middle of a session (true) or is back
    /// (false). Leaving tells the iPhone, which shows that the iPad is gone, and the link answers
    /// no ping until it is back.
    func setHostAway(_ away: Bool) async
    func stop() async
}
