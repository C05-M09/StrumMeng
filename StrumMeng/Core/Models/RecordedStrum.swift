import Foundation

/// One swipe the player made during a session, kept so Replay can play back every input exactly as
/// it happened, including strums that did not count.
///
/// Stored inside every session record as JSON. New fields added later must be optional, otherwise
/// records saved by older versions of the app can no longer be decoded.
nonisolated struct RecordedStrum: Codable, Sendable, Equatable {
    /// Session time of the touch: seconds after step 0 (negative during the count-in). Raw touch
    /// time, without the latency offset, because Replay plays it back as it was heard.
    let time: TimeInterval
    let direction: StrumDirection
    /// True when the strum was not used to judge any node (a swipe on a rest or a second swipe for
    /// the same node). Such strums count as a Miss in the session's accuracy.
    let isExtra: Bool
}
