import Foundation

/// A sound in a replay, at its session time (seconds after step 0).
///
/// Replay sounds like Play did: the metronome on every quarter note and the player's own strums at
/// their recorded times. A strum's direction is not stored, so it takes the direction of the note it
/// was judged against; a Miss with no recorded strum makes no sound.
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
            guard let offsetMs = event.offsetMs, !pattern.strokes.isEmpty else { continue }
            let direction: StrumDirection
            switch pattern.strokes[event.stepIndex % pattern.strokes.count] {
            case .down: direction = .down
            case .up: direction = .up
            case .rest: continue
            }
            let time = Double(event.stepIndex) * stepInterval + offsetMs / 1000
            cues.append(ReplayCue(time: time, sound: .strum(direction)))
        }
        return cues.sorted { $0.time < $1.time }
    }
}
