import Foundation

/// What the controller link is doing (ARCHITECTURE.md §3.2.4). Drives the connection screens and
/// the connected indicator.
nonisolated enum ControllerConnectionState: Sendable, Equatable {
    case unpaired, pairing, searching, reconnecting
    case connected(latencyMs: Double)
}
