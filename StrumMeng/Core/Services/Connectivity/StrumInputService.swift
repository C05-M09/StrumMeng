import Foundation

/// Where strums come from. Today: swipes on the iPad screen (TouchStrumInputService). Later the
/// iPhone controller link provides the same stream, so the game loop does not change.
protocol StrumInputService: Sendable {
    /// One event per physical strum, de-duplicated, with its time on the iPad host clock.
    var strums: AsyncStream<StrumEvent> { get }
}
