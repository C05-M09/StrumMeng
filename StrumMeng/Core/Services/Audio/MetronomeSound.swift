import Foundation

/// Metronome clicks, scheduled on the same host clock as the beats.
@MainActor
protocol MetronomeSound: AnyObject {
    /// - Parameters:
    ///   - time: HostClock seconds.
    ///   - accent: the first beat of a bar (a higher click).
    func click(at time: TimeInterval, accent: Bool)

    /// Drops clicks scheduled but not played yet (pause, finish, leaving the screen).
    func cancelClicks()
}
