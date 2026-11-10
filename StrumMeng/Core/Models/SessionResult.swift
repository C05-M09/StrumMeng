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
    /// Nodes judged Miss plus extra strums (see `RecordedStrum.isExtra`).
    let missCount: Int
    let createdAt: Date
    let beatEvents: [BeatEvent]

    /// Every swipe of the session in time order, for Replay. Empty for records saved before strums
    /// were recorded.
    let strums: [RecordedStrum]

    init(id: UUID, patternID: String, songID: String?, bpm: Int, accuracy: Double,
         perfectCount: Int, tooEarlyCount: Int, missCount: Int, createdAt: Date,
         beatEvents: [BeatEvent], strums: [RecordedStrum] = []) {
        self.id = id
        self.patternID = patternID
        self.songID = songID
        self.bpm = bpm
        self.accuracy = accuracy
        self.perfectCount = perfectCount
        self.tooEarlyCount = tooEarlyCount
        self.missCount = missCount
        self.createdAt = createdAt
        self.beatEvents = beatEvents
        self.strums = strums
    }

    /// Swipes that were not used to judge any node.
    var extraStrumCount: Int {
        strums.filter(\.isExtra).count
    }
}
