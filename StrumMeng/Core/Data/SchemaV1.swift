import Foundation
import SwiftData

/// The first persisted schema.
///
/// When `PracticeSessionRecord` changes, leave this enum untouched, add a `SchemaV2`
/// with the new shape, and add a stage to `SessionMigrationPlan`.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [PracticeSessionRecord.self] }

    /// One finished session. Saved exactly once, when the Summary first appears.
    @Model
    final class PracticeSessionRecord {
        @Attribute(.unique) var id: UUID
        var patternID: String

        /// `nil` means a Practice session; a value means a Showtime session.
        var songID: String?

        var bpm: Int
        var accuracy: Double
        var perfectCount: Int
        var tooEarlyCount: Int
        var missCount: Int
        var createdAt: Date

        /// JSON-encoded `[BeatEvent]`, kept as opaque data so that changing `BeatEvent`
        /// never changes the database schema.
        var beatEventsData: Data

        init(
            id: UUID,
            patternID: String,
            songID: String?,
            bpm: Int,
            accuracy: Double,
            perfectCount: Int,
            tooEarlyCount: Int,
            missCount: Int,
            createdAt: Date,
            beatEventsData: Data
        ) {
            self.id = id
            self.patternID = patternID
            self.songID = songID
            self.bpm = bpm
            self.accuracy = accuracy
            self.perfectCount = perfectCount
            self.tooEarlyCount = tooEarlyCount
            self.missCount = missCount
            self.createdAt = createdAt
            self.beatEventsData = beatEventsData
        }
    }
}
