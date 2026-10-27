import Foundation

struct StrumPattern: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let name: String
    let strokes: [Stroke]
    let beatLabels: [String]
    let beatsPerPattern: Int
    let suggestedOrder: Int
    let defaultBPM: Int
}

extension StrumPattern {
    /// Default number of pattern repetitions in a practice session.
    static let defaultRepetitions = 10

    /// Duration of one complete loop of the pattern at the given BPM (in seconds).
    ///
    /// Assumes 8th-note subdivision in 4/4 time (2 strokes per beat).
    func loopDuration(at bpm: Int) -> TimeInterval {
        guard bpm > 0 else { return 0 }
        let secondsPerBeat = 60.0 / Double(bpm)
        let beatsCount = Double(strokes.count) / 2.0
        return secondsPerBeat * beatsCount
    }

    /// Total duration for practicing this pattern with the specified number of repetitions.
    func sessionDuration(at bpm: Int, repetitions: Int = defaultRepetitions) -> TimeInterval {
        loopDuration(at: bpm) * Double(repetitions)
    }

    /// Total number of stroke steps across the session.
    func totalStrumSteps(repetitions: Int = defaultRepetitions) -> Int {
        strokes.count * repetitions
    }
}
