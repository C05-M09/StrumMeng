import Foundation

/// The direction or action of a strum in a pattern.
///
/// Each beat or sub-beat in a `StrumPattern` is represented by a `Stroke`.
enum Stroke: String, Codable, Sendable, CaseIterable, Equatable {
    case down
    case up
    case rest
}
