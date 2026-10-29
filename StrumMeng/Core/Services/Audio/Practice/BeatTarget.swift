import Foundation

/// One judged step as TimingJudge sees it: when it sounds and which way it must be strummed.
/// Built by the view model from a BeatTick (which carries no direction) and the pattern's Stroke.
struct BeatTarget: Sendable, Equatable {
    let index: Int
    /// iPad host-clock seconds.
    let expectedTime: TimeInterval
    let direction: StrumDirection
}
