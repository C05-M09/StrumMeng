import Foundation

/// What the hit ring and nodes show. Mirrors BeatResult, which is what gets stored.
enum PlayFeedback: Equatable {
    case perfect, tooEarly, miss

    init(_ result: BeatResult) {
        switch result {
        case .perfect: self = .perfect
        case .tooEarly: self = .tooEarly
        case .miss: self = .miss
        }
    }
}
