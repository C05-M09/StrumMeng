import Foundation

/// Turns the judged beats of a finished session into the SessionResult that Summary, Replay and
/// the pattern records use. Pure. A session ended by Restart or Back to Menu never gets here.
enum SessionResultBuilder {
    static func build(id: UUID,
                      patternID: String,
                      bpm: Int,
                      beatEvents: [BeatEvent],
                      createdAt: Date) -> SessionResult {
        let beats = beatEvents.sorted { $0.stepIndex < $1.stepIndex }
        let perfect = beats.filter { $0.result == .perfect }.count
        let tooEarly = beats.filter { $0.result == .tooEarly }.count
        let miss = beats.filter { $0.result == .miss }.count
        return SessionResult(
            id: id,
            patternID: patternID,
            songID: nil,
            bpm: bpm,
            accuracy: beats.isEmpty ? 0 : Double(perfect) / Double(beats.count),
            perfectCount: perfect,
            tooEarlyCount: tooEarly,
            missCount: miss,
            createdAt: createdAt,
            beatEvents: beats
        )
    }
}
