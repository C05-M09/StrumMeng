import Foundation

enum AppRoute: Hashable {
    case practiceList
    /// `visit` makes every opening of Listen a new screen. Without it, Retry at the same tempo would
    /// equal the Listen already in the stack, and SwiftUI would show that old, finished screen again.
    case listen(patternID: String, bpm: Int, visit: UUID = UUID())
    case play(patternID: String, bpm: Int)
    /// A finished session. Carries only its id: the result waits in SessionResultStore.
    case summary(sessionID: UUID)
}
