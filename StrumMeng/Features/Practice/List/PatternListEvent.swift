import Foundation

enum PatternListEvent: Equatable {
    case selectPattern(id: String)
    case decreaseBPM
    case increaseBPM
    /// A tempo chosen elsewhere: Retry on Summary with the recommended or the same BPM.
    case setBPM(Int)
    case tapPlay
    case tapBack
}
