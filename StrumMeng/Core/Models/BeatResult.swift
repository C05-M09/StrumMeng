import Foundation

/// The outcome of a single beat.
///
/// The raw values are written to disk inside `PracticeSessionRecord.beatEventsData`,
/// so never rename a case without a migration. A strum that arrives too late is a
/// `.miss`; there is deliberately no "too late" case.
enum BeatResult: String, Codable, Sendable, Equatable {
    case perfect
    case tooEarly
    case miss
}
