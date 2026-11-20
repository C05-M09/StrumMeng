import Foundation

/// A result shown on screen, and when it appeared (session time in seconds), so it can animate.
struct PlayJudgement: Equatable {
    let feedback: PlayFeedback
    let time: TimeInterval
}
