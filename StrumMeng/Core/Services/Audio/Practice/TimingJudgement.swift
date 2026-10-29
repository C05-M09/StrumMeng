import Foundation

/// A judged beat plus the strum that satisfied it, so that strum cannot satisfy another beat.
struct TimingJudgement: Equatable {
    let event: BeatEvent
    /// nil when the beat is a Miss.
    let strumID: UUID?
}
