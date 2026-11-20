import Foundation

/// The judged result of one beat, emitted by `FeedbackEngine` when that beat's window closes.
///
/// Stored inside every session record so Replay can re-play the exact colour sequence
/// without judging anything again. New fields added later must be optional, otherwise
/// records saved by older versions of the app can no longer be decoded.
struct BeatEvent: Codable, Sendable, Equatable {
    /// Index of the pattern step this beat belongs to.
    let stepIndex: Int

    let result: BeatResult

    /// Distance between the strum and the beat in milliseconds, after latency
    /// compensation. Negative means early. `nil` when no strum was detected.
    ///
    /// Kept so the Summary can count "off tempo" beats from stored data.
    let offsetMs: Double?
}
