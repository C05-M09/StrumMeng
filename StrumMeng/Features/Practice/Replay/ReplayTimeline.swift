import Foundation

/// Pure time maths for Replay's seek. No clock is read here: callers pass the times in, so every
/// rule can be tested without waiting.
enum ReplayTimeline {
    /// The song time `elapsed` real seconds after the anchor, never past the end.
    static func songTime(anchor: TimeInterval, elapsed: TimeInterval, duration: TimeInterval) -> TimeInterval {
        min(anchor + max(0, elapsed), duration)
    }

    /// The song time for a point on the progress bar (0 = first beat, 1 = the end).
    /// Out-of-range or invalid values are clamped, so a drag past either end stops there.
    static func seekTime(progress: Double, duration: TimeInterval) -> TimeInterval {
        guard progress.isFinite, duration > 0 else { return 0 }
        return min(max(progress, 0), 1) * duration
    }
}
