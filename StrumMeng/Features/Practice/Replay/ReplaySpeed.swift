import Foundation

/// How fast Replay plays the stored session. Slower speeds help the player see where a strum went
/// wrong; the colours and the order of events stay exactly those of the original session.
enum ReplaySpeed: Double, CaseIterable, Equatable, Sendable {
    case half = 0.5
    case threeQuarters = 0.75
    case normal = 1
    case oneAndHalf = 1.5

    /// Song seconds that pass per real second.
    var rate: Double { rawValue }

    /// The speed after this one on the speed button, wrapping back to the slowest.
    var next: ReplaySpeed {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return .normal }
        return all[(index + 1) % all.count]
    }

    /// Text on the speed button, for example "0.75×".
    var label: String {
        switch self {
        case .half: return "0.5×"
        case .threeQuarters: return "0.75×"
        case .normal: return "1×"
        case .oneAndHalf: return "1.5×"
        }
    }
}
