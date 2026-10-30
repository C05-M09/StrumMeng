import Foundation

enum AppRoute: Hashable {
    case practiceList
    case listen(patternID: String, bpm: Int)
    case play(patternID: String, bpm: Int)
}
