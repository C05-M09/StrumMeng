import CoreGraphics
import Foundation

/// Pure maths behind the Play animation. Every position is derived from session time, never from a
/// separate animation timer, so the visuals stay locked to the beat whatever drives the time.
enum PlayTimeline {
    static let countLabels = ["1", "&", "2", "&", "3", "&", "4", "&"]
    /// 3-2-1 on quarter notes = 6 eighth-note slots before the first slot.
    static let countInSlots = 6
    /// On READY? the first node waits this many slots before the ring, at the right edge of the lane
    /// (hi-fi "Practice-Play Copy 5"). It starts moving during the count-in and reaches the ring on beat 1.
    static let readyLeadSlots = 3.1

    static func slotInterval(bpm: Int) -> TimeInterval {
        60.0 / Double(max(1, bpm)) / 2
    }

    /// The time the lane is drawn at: session time, but never earlier than the READY? lead-in, so the
    /// nodes hold still while waiting and glide in without a jump once the count-in reaches them.
    static func laneTime(songTime: TimeInterval, slotInterval: TimeInterval) -> TimeInterval {
        max(songTime, -readyLeadSlots * slotInterval)
    }

    /// Repeats one bar of slots (nil = rest) to fill the session.
    static func makeNodes(pattern: [BeatNodeView.Arrow?], slotInterval: TimeInterval,
                          duration: TimeInterval) -> [PlayLaneNode] {
        guard !pattern.isEmpty, slotInterval > 0 else { return [] }
        let count = Int((duration / slotInterval).rounded())
        return (0..<count).map { index in
            PlayLaneNode(index: index, arrow: pattern[index % pattern.count],
                         countLabel: countLabels[index % countLabels.count],
                         time: Double(index) * slotInterval, judgement: nil)
        }
    }

    /// Horizontal centre of a node: in the hit ring at its time, one `slotSpacing` further right per slot
    /// still to come, moving left as time passes.
    static func nodeX(nodeTime: TimeInterval, songTime: TimeInterval, slotInterval: TimeInterval,
                      hitX: CGFloat, slotSpacing: CGFloat) -> CGFloat {
        guard slotInterval > 0 else { return hitX }
        return hitX + CGFloat((nodeTime - songTime) / slotInterval) * slotSpacing
    }

    static func progress(songTime: TimeInterval, duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, songTime / duration))
    }

    /// "00:03 / 01:00". Elapsed time never shows negative (count-in) or past the end.
    static func clockLabel(songTime: TimeInterval, duration: TimeInterval) -> String {
        let elapsed = Int(min(max(0, songTime), duration))
        return "\(mmss(elapsed)) / \(mmss(Int(duration.rounded())))"
    }

    /// 3, 2, 1 during the count-in (one number per quarter note), nil once playing.
    static func countInNumber(songTime: TimeInterval, slotInterval: TimeInterval) -> Int? {
        guard songTime < 0, slotInterval > 0 else { return nil }
        let quartersLeft = Int((-songTime / (slotInterval * 2)).rounded(.up))
        return min(3, max(1, quartersLeft))
    }

    /// 0...1, how far into the current count-in number we are (drives its pop animation).
    static func countInBeatProgress(songTime: TimeInterval, slotInterval: TimeInterval) -> Double {
        guard songTime < 0, slotInterval > 0 else { return 1 }
        let quarter = slotInterval * 2
        let intoBeat = (songTime + Double(countInSlots) * slotInterval).truncatingRemainder(dividingBy: quarter)
        return min(1, max(0, intoBeat / quarter))
    }

    private static func mmss(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
