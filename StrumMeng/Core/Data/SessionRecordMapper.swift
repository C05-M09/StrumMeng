import Foundation

/// Converts between the SwiftData record and the plain `SessionResult`.
///
/// This is the only place that knows `beatEventsData` is JSON. Keeping the record out of
/// the rest of the app is what lets the schema change without touching any view model.
enum SessionRecordMapper {
    static func makeRecord(from result: SessionResult) throws -> PracticeSessionRecord {
        let data: Data
        do {
            data = try JSONEncoder().encode(result.beatEvents)
        } catch {
            throw SessionRepositoryError.encodingFailed
        }

        return PracticeSessionRecord(
            id: result.id,
            patternID: result.patternID,
            songID: result.songID,
            bpm: result.bpm,
            accuracy: result.accuracy,
            perfectCount: result.perfectCount,
            tooEarlyCount: result.tooEarlyCount,
            missCount: result.missCount,
            createdAt: result.createdAt,
            beatEventsData: data
        )
    }

    static func makeResult(from record: PracticeSessionRecord) throws -> SessionResult {
        let events: [BeatEvent]
        do {
            events = try JSONDecoder().decode([BeatEvent].self, from: record.beatEventsData)
        } catch {
            throw SessionRepositoryError.decodingFailed(recordID: record.id)
        }

        return SessionResult(
            id: record.id,
            patternID: record.patternID,
            songID: record.songID,
            bpm: record.bpm,
            accuracy: record.accuracy,
            perfectCount: record.perfectCount,
            tooEarlyCount: record.tooEarlyCount,
            missCount: record.missCount,
            createdAt: record.createdAt,
            beatEvents: events
        )
    }
}
