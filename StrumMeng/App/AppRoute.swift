import Foundation

enum AppRoute: Hashable {
    case practiceList
    case listen(patternID: String, bpm: Int)
    case play(patternID: String, bpm: Int)
    /// A finished session. Carries only its id: the result waits in SessionResultStore.
    case summary(sessionID: UUID)
}
