import Foundation

/// What the iPad's Set Up Device screen shows.
enum DeviceSetupState: Equatable {
    case searching
    case connected(latencyMs: Double)
    case reconnecting
    /// The link could not start, for example with no Local Network permission.
    case failed
}
