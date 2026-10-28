import Foundation

/// Everything the Play screen draws for one frame. Plain values only, so the screen can be previewed in
/// every state and later fed by the view model from BeatClock time.
struct PlayScreenModel: Equatable {
    let title: String
    let bpm: Int
    let duration: TimeInterval
    let slotInterval: TimeInterval
    /// Seconds since the first slot. Negative during the count-in.
    let songTime: TimeInterval
    let phase: PlayScreenPhase
    let nodes: [PlayLaneNode]
    /// The most recent result, which colours the hit ring.
    let lastJudgement: PlayJudgement?
    /// Session time of the player's latest swipe, judged or not, so the ring can react to every swipe.
    var lastStrumTime: TimeInterval?
}
