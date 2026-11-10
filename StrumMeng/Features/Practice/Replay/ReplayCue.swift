import Foundation

/// A sound in a replay, at its session time (seconds after step 0).
///
/// Replay sounds like Play did: the metronome on every quarter note and every swipe the player made,
/// at its recorded time and in its own direction, including wrong and extra ones.
///
/// Records saved before every swipe was stored have only the judged strums: those replay at their
/// node's time plus offset, in the node's direction, and a Miss with no strum makes no sound.
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
        if !result.strums.isEmpty {
            cues += result.strums.map { ReplayCue(time: $0.time, sound: .strum($0.direction)) }
            return cues.sorted { $0.time < $1.time }
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
