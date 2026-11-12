/// Sample arrangements for flow testing, not transcriptions of the real songs.
@MainActor
struct DummySongCatalog: SongCatalog {
    let songs: [Song] = [
        Song(id: "dummy-twinkle", title: "Twinkle Twinkle Little Star", bpm: 80,
             patternID: "foundation", strokes: [.down, .rest, .down, .rest, .down, .rest, .down, .rest],
             barCount: 20, chords: Self.changes(bars: 20, progression: ["C", "F", "C", "G"])),
        Song(id: "dummy-jingle", title: "Jingle Bells", bpm: 96,
             patternID: "subdivision", strokes: [.down, .up, .down, .up, .down, .up, .down, .up],
             barCount: 24, chords: Self.changes(bars: 24, progression: ["C", "C", "F", "G"]),
             patternChanges: [SongPatternChange(slot: 96, pattern: PatternCatalog.all[0])])
    ]
    private static func changes(bars: Int, progression: [String]) -> [SongChordChange] {
        (0..<bars).map { SongChordChange(slot: $0 * 8, chord: progression[$0 % progression.count]) }
    }
}
