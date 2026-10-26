import Foundation

enum AppRoute: Hashable {
    case listen(patternID: String, bpm: Int)
}
