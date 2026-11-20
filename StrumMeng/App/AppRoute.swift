import Foundation

enum AppRoute: Hashable {
    case showtimeList
    case showtime(songID: String, visit: UUID = UUID())
    case practiceList
    /// `visit` makes every opening of Listen a new screen. Without it, Retry at the same tempo would
    /// equal the Listen already in the stack, and SwiftUI would show that old, finished screen again.
    case listen(patternID: String, bpm: Int, visit: UUID = UUID())
    case play(patternID: String, bpm: Int)
    /// A finished session. Carries its id (result waits in SessionResultStore), whether to show intro overlay, and whether retry is available.
    case summary(sessionID: UUID, showIntroOverlay: Bool = true, canRetry: Bool = true)
    case deviceSetup
}
