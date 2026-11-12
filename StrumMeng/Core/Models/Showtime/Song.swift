import Foundation

/// Temporary, in-memory song contract. The catalogue adapter can later load persisted data.
struct Song: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let bpm: Int
    let patternID: String
    let strokes: [Stroke]
    let barCount: Int
    let chords: [SongChordChange]
    var patternChanges: [SongPatternChange] = []
}
