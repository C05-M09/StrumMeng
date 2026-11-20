import Foundation

/// Direction of a swipe. Carried on every strum, but not judged in the MVP (ARCHITECTURE.md §4.1).
enum StrumDirection: String, Codable, Sendable, Equatable {
    case down
    case up
}
