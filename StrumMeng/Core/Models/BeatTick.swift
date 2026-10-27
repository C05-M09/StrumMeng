import Foundation

/// One tick of the BeatClock. The clock ticks once per pattern step (an eighth note in 4/4),
/// including the count-in steps.
struct BeatTick: Sendable, Equatable {
    let index: Int
    /// When this step sounds, in iPad host-clock seconds.
    let expectedTime: TimeInterval
}
