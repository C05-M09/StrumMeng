import Foundation

/// A sound in a replay, at its session time (seconds after step 0).
///
/// Replay sounds like Play did: the metronome on every quarter note and the player's strums at
/// their recorded times. If a beat was judged as a Miss (wrong strum or missed beat), it plays
/// with the wrong strum direction so the player can audibly hear their mistake during replay.
struct ReplayCue: Equatable {
    enum Sound: Equatable {
        case strum(StrumDirection)
        case click(accent: Bool)
    }

    let time: TimeInterval
    let sound: Sound

    /// Every cue of a session, sorted by time.
    static func cues(for result: SessionResult, pattern: StrumPattern,
                     stepInterval: TimeInterval, totalSteps: Int) -> [ReplayCue] {
        var cues: [ReplayCue] = []
        for step in stride(from: 0, to: totalSteps, by: 2) {
            let accent = !pattern.strokes.isEmpty && step.isMultiple(of: pattern.strokes.count)
            cues.append(ReplayCue(time: Double(step) * stepInterval, sound: .click(accent: accent)))
        }
        for event in result.beatEvents {
            guard !pattern.strokes.isEmpty else { continue }
            let stroke = pattern.strokes[event.stepIndex % pattern.strokes.count]
            let direction: StrumDirection
            if event.result == .miss {
                // Wrong strum: opposite direction of the pattern stroke (or down on rest)
                switch stroke {
                case .down: direction = .up
                case .up: direction = .down
                case .rest: direction = .down
                }
            } else {
                switch stroke {
                case .down: direction = .down
                case .up: direction = .up
                case .rest: continue
                }
            }
            let time = Double(event.stepIndex) * stepInterval + (event.offsetMs ?? 0) / 1000
            cues.append(ReplayCue(time: time, sound: .strum(direction)))
        }
        return cues.sorted { $0.time < $1.time }
    }
}
