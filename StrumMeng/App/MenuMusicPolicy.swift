import Foundation

/// Decides on which screens the menu background music plays.
///
/// It plays on Home (with its Option and Guidebook overlays), the pattern list, and the Practice
/// and Showtime summaries. Set Up Device is quiet.
/// Showtime song list plays the character's own song, so menu music is paused there.
/// It is paused on Listen, Play and Replay: they play the guitar and the metronome, and the player
/// must hear those clearly to strum on tempo. Replay opens over the summary in the same route, and
/// the Showtime summary shares the `.showtime` route with its Listen and Play, so on those routes
/// the summary view reports whether it is showing (`isShowingSummary`).
enum MenuMusicPolicy {
    /// - Parameters:
    ///   - top: the route on top of the stack; nil is Home.
    ///   - isAppActive: false while the app is inactive or in the background, which always pauses.
    ///   - isShowingSummary: true while a Practice or Showtime summary is on screen without Replay.
    static func playsMusic(on top: AppRoute?, isAppActive: Bool, isShowingSummary: Bool = false) -> Bool {
        guard isAppActive else { return false }
        switch top {
        case nil, .practiceList:
            return true
        case .summary, .showtime:
            return isShowingSummary
        case .showtimeList, .deviceSetup, .listen, .play:
            return false
        }
    }
}
