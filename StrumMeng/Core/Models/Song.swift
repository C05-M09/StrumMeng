import Foundation

/// One bar of a song. The chord is a plain name such as "C" or "Am".
nonisolated struct SongBar: Sendable, Codable, Hashable {
    let chord: String
}

/// A part of a song (Verse, Chorus) that is strummed with one pattern.
nonisolated struct SongSection: Sendable, Codable, Hashable {
    let name: String
    /// Stable id of a `StrumPattern` in `PatternCatalog`.
    let patternID: String
    let bars: [SongBar]
}

nonisolated struct Song: Sendable, Codable, Hashable, Identifiable {
    /// Stable slug. Saved as `songID` in `SessionResult`, so it must never change.
    let id: String
    let title: String
    /// Fixed tempo of the song. The user cannot change it.
    let bpm: Int
    let sections: [SongSection]
    let suggestedOrder: Int

    static let beatsPerBar = 4

    var barCount: Int {
        sections.reduce(0) { $0 + $1.bars.count }
    }

    /// Length of one run through the whole song.
    var durationSeconds: Double {
        Double(barCount * Song.beatsPerBar) * 60.0 / Double(bpm)
    }

    /// Chords in order of first appearance, e.g. ["C", "F", "G"]. Shown on the detail card.
    var distinctChords: [String] {
        var seen = Set<String>()
        return sections.flatMap(\.bars).map(\.chord).filter { seen.insert($0).inserted }
    }

    /// Pattern of the first section. Its name is shown on the detail card.
    var primaryPatternID: String? {
        sections.first?.patternID
    }
}
