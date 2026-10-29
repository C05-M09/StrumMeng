import Foundation

enum AppRoute: Hashable {
    case practiceList
    case listen(patternID: String, bpm: Int)
}
