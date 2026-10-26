import Foundation

/// A finished session as the rest of the app sees it.
///
/// Views and view models only ever touch this type, never the SwiftData record behind it.
struct SessionResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let patternID: String

    /// `nil` for a Practice session, the song's id for a Showtime session.
    let songID: String?

    let bpm: Int

    /// A fraction from 0 to 1. The UI multiplies by 100 for display.
    let accuracy: Double

    let perfectCount: Int
    let tooEarlyCount: Int
    let missCount: Int
    let createdAt: Date
    let beatEvents: [BeatEvent]
}
