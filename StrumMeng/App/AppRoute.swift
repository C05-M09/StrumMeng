import Foundation

enum AppRoute: Hashable {
    case listen(patternID: String, bpm: Int)
    case play(patternID: String, bpm: Int)
}
