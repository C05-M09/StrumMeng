#if DEBUG
import SwiftUI

/// Preview-only stand-in for the game loop: a fake session clock and scripted results, so the Play
/// screen's animation can be checked before the team's models and view model exist.
/// Starts on READY?; tap to count in. Not shipped (DEBUG only). The real screen takes its time from
/// the BeatClock instead.
struct PracticePlayDemoView: View {
    var title = "Subdivision Strum"
    var bpm = 80
    var pattern: [BeatNodeView.Arrow?] = [.down, .up, .down, .up, .down, .up, .down, .up]

    /// nil = waiting on READY?.
    @State private var start: Date?
    @State private var pausedAt: Date?

    static let duration: TimeInterval = 60
    /// Results the fake player gets, in order, one per strum slot.
    private static let script: [PlayFeedback] = [.perfect, .perfect, .tooEarly, .perfect, .miss, .perfect, .perfect, .tooEarly]

    var body: some View {
        PracticePlayView(
            isAnimating: start != nil && pausedAt == nil,
            liveModel: { frameModel(at: .now) },
            onReady: { start = .now; pausedAt = nil },
            onPause: { if start != nil { pausedAt = .now } },
            onResume: {
                if let pausedAt, let begun = start { start = begun + Date.now.timeIntervalSince(pausedAt) }
                pausedAt = nil
            },
            onRestart: { start = .now; pausedAt = nil },
            onBackToMenu: { start = nil; pausedAt = nil }
        )
    }

    private func frameModel(at date: Date) -> PlayScreenModel {
        let slot = PlayTimeline.slotInterval(bpm: bpm)
        let countIn = Double(PlayTimeline.countInSlots) * slot
        let elapsed = start.map { (pausedAt ?? date).timeIntervalSince($0) } ?? 0
        // After the session and a short tail, go back to READY? for another run.
        let finished = elapsed > countIn + Self.duration + 1.5
        return (start == nil || finished)
            ? Self.model(title: title, bpm: bpm, pattern: pattern, songTime: -countIn, ready: true)
            : Self.model(title: title, bpm: bpm, pattern: pattern, songTime: elapsed - countIn,
                         paused: pausedAt != nil)
    }

    /// A frame of the scripted session at `songTime`.
    static func model(title: String = "Subdivision Strum",
                      bpm: Int = 80,
                      pattern: [BeatNodeView.Arrow?] = [.down, .up, .down, .up, .down, .up, .down, .up],
                      songTime: TimeInterval,
                      ready: Bool = false,
                      paused: Bool = false) -> PlayScreenModel {
        let slot = PlayTimeline.slotInterval(bpm: bpm)
        var nodes = PlayTimeline.makeNodes(pattern: pattern, slotInterval: slot, duration: duration)
        var last: PlayJudgement?
        var strumCount = 0
        for index in nodes.indices where nodes[index].arrow != nil {
            let feedback = script[strumCount % script.count]
            strumCount += 1
            let offset: TimeInterval = switch feedback {
            case .perfect: 0.01
            case .tooEarly: -0.12
            case .miss: 0.06          // judged when the window closes, just after the beat
            }
            let time = nodes[index].time + offset
            guard time <= songTime else { continue }
            let judgement = PlayJudgement(feedback: feedback, time: time)
            nodes[index].judgement = judgement
            if time > last?.time ?? -.infinity { last = judgement }
        }

        let phase: PlayScreenPhase
        if ready {
            phase = .ready
        } else if paused {
            phase = .paused
        } else if let number = PlayTimeline.countInNumber(songTime: songTime, slotInterval: slot) {
            phase = .countIn(number)
        } else {
            phase = .playing
        }
        // The scripted player swipes at each hit (a Miss here means no swipe at all).
        let lastSwipe = last.flatMap { $0.feedback == .miss ? nil : $0.time }
        return PlayScreenModel(title: title, bpm: bpm, duration: duration, slotInterval: slot,
                               songTime: songTime, phase: phase, nodes: nodes, lastJudgement: last,
                               lastStrumTime: lastSwipe)
    }
}

// "Animated" runs the whole flow: READY? (tap) -> 3-2-1 -> play, with a working pause modal.
// The static previews match the hi-fi frames one by one.

#Preview("Animated", traits: .landscapeLeft) {
    PracticePlayDemoView()
}

#Preview("Animated - Syncopation", traits: .landscapeLeft) {
    PracticePlayDemoView(title: "Syncopation Strum",
                         pattern: [.down, nil, .down, .up, nil, .up, .down, .up])
}

#Preview("Ready?", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: -2.25, ready: true))
}

#Preview("Count-in 2", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: -1.3))
}

#Preview("Playing 00:03", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 3.2))
}

#Preview("Perfect", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 0.05))
}

#Preview("Too early", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 0.75 - 0.08))
}

#Preview("Miss", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 1.5 + 0.12))
}

#Preview("End 00:59", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 59.9))
}

#Preview("Paused", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(title: "Syncopation Strum",
                                                       pattern: [.down, nil, .down, .up, nil, .up, .down, .up],
                                                       songTime: 5, paused: true))
}
#endif
