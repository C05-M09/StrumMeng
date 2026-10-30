import Foundation

/// The guitar the iPad plays: the Listen example and the player's own strums in Play.
@MainActor
protocol GuitarSound: AnyObject {
    /// Synthesises the notes ahead of time, so the first strum is not late. Safe to call again.
    func prepare() async

    /// - Parameters:
    ///   - time: when the strum starts, in HostClock seconds; nil = as soon as possible.
    ///   - accent: 0...1, how hard the strum is.
    func strum(_ direction: StrumDirection, at time: TimeInterval?, accent: Double)

    /// Silences every string and drops strums scheduled but not played yet.
    func stopStrums()
}
