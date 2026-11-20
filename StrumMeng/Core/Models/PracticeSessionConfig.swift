import Foundation

enum PracticeSessionConfig {
    static let patternRepetitions = 10

    static func durationSeconds(for pattern: StrumPattern, bpm: Int) -> TimeInterval {
        guard bpm > 0 else { return 0 }

        let totalBeats = pattern.beatsPerPattern * patternRepetitions
        return Double(totalBeats) * 60 / Double(bpm)
    }

    static func durationLabel(for pattern: StrumPattern, bpm: Int) -> String {
        durationLabel(seconds: durationSeconds(for: pattern, bpm: bpm))
    }

    /// "45 sec", "1 min", "1 min 20 sec". Shared with the Showtime summary's song length.
    static func durationLabel(seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds.rounded())

        guard totalSeconds >= 60 else {
            return "\(totalSeconds) sec"
        }

        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60

        guard remainingSeconds > 0 else {
            return "\(minutes) min"
        }

        return "\(minutes) min \(remainingSeconds) sec"
    }
}
