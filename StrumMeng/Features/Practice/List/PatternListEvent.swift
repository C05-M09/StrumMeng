import Foundation

enum PatternListEvent: Equatable {
    case selectPattern(id: String)
    case decreaseBPM
    case increaseBPM
    case tapPlay
    case tapBack
}
