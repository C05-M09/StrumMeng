import Foundation

/// The musical phrase is repeated on the beat grid, excluding the recording's trailing silence.
nonisolated struct SongLoopConfiguration: Sendable, Equatable {
    let barsPerLoop: Int
    let bpm: Int
    let count: Int

    var durationPerLoop: TimeInterval { Double(barsPerLoop * 4) * 60 / Double(bpm) }

    static let rowBoat = SongLoopConfiguration(barsPerLoop: 4, bpm: 110, count: 3)
}
