import Foundation

/// Turns the judged beats of a finished session into the SessionResult that Summary, Replay and
/// the pattern records use. Pure. A session ended by Restart or Back to Menu never gets here.
///
/// Accuracy = (Perfect + half a point per Too Early) / (nodes + extra strums). An extra strum (a
/// swipe that judged no node) counts as a Miss, so swiping on rests lowers the score.
enum SessionResultBuilder {
    /// Points for a Too Early node; a Perfect is worth 1, a Miss 0.
    static let tooEarlyCredit = 0.5

    static func build(id: UUID,
                      patternID: String,
                      songID: String? = nil,
                      bpm: Int,
                      beatEvents: [BeatEvent],
                      strums: [RecordedStrum] = [],
                      createdAt: Date) -> SessionResult {
        let beats = beatEvents.sorted { $0.stepIndex < $1.stepIndex }
        let perfect = beats.filter { $0.result == .perfect }.count
        let tooEarly = beats.filter { $0.result == .tooEarly }.count
        let extra = strums.filter(\.isExtra).count
        let miss = beats.filter { $0.result == .miss }.count + extra
        let scored = beats.count + extra
        let points = Double(perfect) + Double(tooEarly) * tooEarlyCredit
        return SessionResult(
            id: id,
            patternID: patternID,
            songID: songID,
            bpm: bpm,
            accuracy: scored == 0 ? 0 : points / Double(scored),
            perfectCount: perfect,
            tooEarlyCount: tooEarly,
            missCount: miss,
            createdAt: createdAt,
            beatEvents: beats,
            strums: strums.sorted { $0.time < $1.time }
        )
    }
}
