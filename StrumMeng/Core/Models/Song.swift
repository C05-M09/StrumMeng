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

/// Showtime song contract. Supports both carousel metadata and gameplay timeline.
struct Song: Identifiable, Equatable, Sendable, Hashable {
    /// Stable slug. Saved as `songID` in `SessionResult`, so it must never change.
    let id: String
    let title: String
    /// Fixed tempo of the song. The user cannot change it.
    let bpm: Int
    var patternID: String
    var strokes: [Stroke]
    var barCount: Int
    var chords: [SongChordChange]
    var patternChanges: [SongPatternChange] = []

    var sections: [SongSection] = []
    var suggestedOrder: Int = 0

    static let beatsPerBar = 4

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Length of one run through the whole song.
    var durationSeconds: Double {
        Double(barCount * Song.beatsPerBar) * 60.0 / Double(bpm)
    }

    /// Chords in order of first appearance, e.g. ["C", "F", "G"]. Shown on the detail card.
    var distinctChords: [String] {
        if !sections.isEmpty {
            var seen = Set<String>()
            return sections.flatMap(\.bars).map(\.chord).filter { seen.insert($0).inserted }
        }
        var seen = Set<String>()
        return chords.map(\.chord).filter { seen.insert($0).inserted }
    }

    /// Pattern of the first section. Its name is shown on the detail card.
    var primaryPatternID: String? {
        sections.first?.patternID ?? (patternID.isEmpty ? nil : patternID)
    }

    init(
        id: String,
        title: String,
        bpm: Int,
        patternID: String = "",
        strokes: [Stroke] = [],
        barCount: Int = 0,
        chords: [SongChordChange] = [],
        patternChanges: [SongPatternChange] = [],
        sections: [SongSection] = [],
        suggestedOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.bpm = bpm
        let resolvedPatternID = patternID.isEmpty ? (sections.first?.patternID ?? "") : patternID
        self.patternID = resolvedPatternID

        if !strokes.isEmpty {
            self.strokes = strokes
        } else if let pattern = PatternCatalog.pattern(forID: resolvedPatternID) {
            self.strokes = pattern.strokes
        } else {
            self.strokes = []
        }

        let resolvedBarCount = barCount > 0 ? barCount : sections.reduce(0) { $0 + $1.bars.count }
        self.barCount = resolvedBarCount

        if !chords.isEmpty {
            self.chords = chords
        } else if !sections.isEmpty {
            var allChords: [SongChordChange] = []
            var currentBar = 0
            for section in sections {
                for bar in section.bars {
                    allChords.append(SongChordChange(slot: currentBar * 8, chord: bar.chord))
                    currentBar += 1
                }
            }
            self.chords = allChords
        } else {
            self.chords = []
        }

        if !patternChanges.isEmpty {
            self.patternChanges = patternChanges
        } else if !sections.isEmpty {
            var changes: [SongPatternChange] = []
            var currentBar = 0
            var activePatternID = resolvedPatternID
            for section in sections {
                if section.patternID != activePatternID,
                   let pattern = PatternCatalog.pattern(forID: section.patternID) {
                    changes.append(SongPatternChange(slot: currentBar * 8, pattern: pattern))
                    activePatternID = section.patternID
                }
                currentBar += section.bars.count
            }
            self.patternChanges = changes
        } else {
            self.patternChanges = []
        }

        self.sections = sections
        self.suggestedOrder = suggestedOrder
    }
}
