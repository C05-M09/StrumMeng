import Foundation

/// Turns a calibration round (the player strums along to plain quarter-note beats) into a latency
/// offset for TimingJudge. Pure, so the debug round now and the Option calibration screen later
/// share it.
///
/// The result is the median offset of the strums that were clearly aimed at a beat: the median
/// ignores a few sloppy strums, and strums far from any beat are dropped first.
nonisolated enum LatencyCalibrator {
    /// A strum further than this from its nearest beat was not aimed at it, so it is ignored.
    static let maxOffset: TimeInterval = 0.25
    /// Fewer usable strums than this give no result rather than a guess.
    static let minimumSamples = 8

    /// How far a strum is from the nearest beat; positive = late.
    /// - Parameters:
    ///   - songTime: the strum's time, with beat 0 at song time 0.
    ///   - beatInterval: time between the beats the player strums to.
    static func offset(ofStrumAt songTime: TimeInterval, beatInterval: TimeInterval) -> TimeInterval {
        guard beatInterval > 0 else { return 0 }
        let nearestBeat = (songTime / beatInterval).rounded() * beatInterval
        return songTime - nearestBeat
    }

    /// The latency offset to use, or nil when there are not enough usable strums.
    static func estimate(from offsets: [TimeInterval]) -> TimeInterval? {
        let usable = offsets.filter { abs($0) <= maxOffset }.sorted()
        guard usable.count >= minimumSamples else { return nil }
        let middle = usable.count / 2
        return usable.count.isMultiple(of: 2) ? (usable[middle - 1] + usable[middle]) / 2 : usable[middle]
    }
}
