import Foundation

/// One strum from the player, already on the iPad host clock.
struct StrumEvent: Identifiable, Codable, Sendable, Equatable {
    /// Used to de-duplicate redundant copies from the iPhone link.
    let id: UUID
    let direction: StrumDirection
    /// When the finger moved, in iPad host-clock seconds (never the arrival time).
    let time: TimeInterval
}
