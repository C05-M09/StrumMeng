import Foundation

/// Where a song's recording fades out and stops, in session time (0 = the first node), so a
/// recording longer than its chart ends with the gameplay instead of playing on through Summary.
nonisolated struct SongBackingTrackEnding: Sendable, Equatable {
    /// Eighth-note steps in one bar: 1 & 2 & 3 & 4 &.
    static let stepsPerBar = Song.beatsPerBar * 2

    /// Still at full level here: the start of the bar that holds the last node.
    let fadeStart: TimeInterval
    /// Silent here, and the recording stops: the last node.
    let end: TimeInterval

    /// Fades over the bar that holds the last node and ends on it. When the last node is the bar's
    /// first step, the fade takes the bar before it. nil when the chart has no node.
    static func forChart(strokes: [Stroke], stepInterval: TimeInterval) -> SongBackingTrackEnding? {
        guard let last = strokes.lastIndex(where: { $0 != .rest }), last > 0 else { return nil }
        var barStart = last / stepsPerBar * stepsPerBar
        if barStart == last { barStart = max(0, last - stepsPerBar) }
        return SongBackingTrackEnding(fadeStart: Double(barStart) * stepInterval,
                                      end: Double(last) * stepInterval)
    }

    /// Level of the recording at a session time: 1 before the fade, 0 from the end on. Eased
    /// (squared), because a straight line in amplitude sounds like it drops away only at the end.
    func gain(atSongTime time: TimeInterval) -> Double {
        guard end > fadeStart else { return time < end ? 1 : 0 }
        let remaining = min(1, max(0, (end - time) / (end - fadeStart)))
        return remaining * remaining
    }
}
