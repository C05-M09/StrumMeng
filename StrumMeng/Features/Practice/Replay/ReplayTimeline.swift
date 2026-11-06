import Foundation

/// Pure time maths for Replay's speed and seek. No clock is read here: callers pass the times in,
/// so every rule can be tested without waiting.
enum ReplayTimeline {
    /// The song time `elapsed` real seconds after the anchor, at `rate`, never past the end.
    static func songTime(
        anchor: TimeInterval,
        elapsed: TimeInterval,
        rate: Double,
        duration: TimeInterval
    ) -> TimeInterval {
        min(anchor + max(0, elapsed) * rate, duration)
    }

    /// The song time for a point on the progress bar (0 = first beat, 1 = the end).
    /// Out-of-range or invalid values are clamped, so a drag past either end stops there.
    static func seekTime(progress: Double, duration: TimeInterval) -> TimeInterval {
        guard progress.isFinite, duration > 0 else { return 0 }
        return min(max(progress, 0), 1) * duration
    }

    /// Real seconds until a sound `songDelta` song seconds ahead must play, at `rate`.
    /// At 0.5× a cue one song second ahead is two real seconds away.
    static func realDelay(songDelta: TimeInterval, rate: Double) -> TimeInterval {
        guard rate > 0 else { return songDelta }
        return songDelta / rate
    }

    /// How much song time fits in a real-time lookahead window at `rate`, so sounds are always
    /// handed to the audio engine the same real time ahead, whatever the speed.
    static func songLookahead(realLookahead: TimeInterval, rate: Double) -> TimeInterval {
        realLookahead * max(rate, 0)
    }
}
