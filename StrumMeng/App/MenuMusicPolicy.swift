import Foundation

/// Decides on which screens the menu background music plays.
///
/// It plays on Home (with its Option and Guidebook overlays) and the pattern list.
/// Set Up Device is quiet, like the screens from Listen on.
/// It is paused from Listen on: Listen, Play and Summary (with Replay) play the guitar and the
/// metronome, and the player must hear those clearly to strum on tempo.
enum MenuMusicPolicy {
    /// - Parameters:
    ///   - top: the route on top of the stack; nil is Home.
    ///   - isAppActive: false while the app is inactive or in the background, which always pauses.
    static func playsMusic(on top: AppRoute?, isAppActive: Bool) -> Bool {
        guard isAppActive else { return false }
        switch top {
        case nil, .practiceList, .showtimeList, .deviceSetup:
            return true
        case .deviceSetup, .listen, .play, .summary:
            return false
        }
    }
}
