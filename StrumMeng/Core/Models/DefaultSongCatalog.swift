import Foundation

/// The 5 Showtime songs. All are public domain, with no lyrics. Chords are one per bar, 4/4.
/// Order requested by user:
/// 1. twinkle-twinkle, 2. jingle bells, 3. abc, 4. row row row your boat, 5. down by the riverside
struct DefaultSongCatalog: SongCatalog {
    static let allowedChords: Set<String> = ["C", "F", "G", "Em", "D", "Am"]

    static let all: [Song] = [
        Song(
            id: "twinkle-twinkle",
            title: "Twinkle Twinkle Little Star",
            bpm: 100,
            sections: [
                SongSection(name: "Verse", patternID: "foundation",
                            bars: bars("C C F C | C G C C | F C G C")),
                SongSection(name: "Chorus", patternID: "foundation",
                            bars: bars("C F C G | C F C G")),
            ],
            suggestedOrder: 1
        ),
        Song(
            id: "jingle-bells",
            title: "Jingle Bells",
            bpm: 120,
            sections: [
                SongSection(name: "Verse", patternID: "subdivision",
                            bars: bars("G G C G | C G D D")),
                SongSection(name: "Chorus", patternID: "subdivision",
                            bars: bars("G G C G | C G D D | G G C G | C G D G")),
            ],
            suggestedOrder: 2
        ),
        Song(
            id: "abc-song",
            title: "ABC Song",
            bpm: 100,
            sections: [
                SongSection(name: "Verse", patternID: "syncopation",
                            bars: bars("C F F G | C C C G | C F F C")),
                SongSection(name: "Chorus", patternID: "syncopation",
                            bars: bars("C F F G | C C C G | C F F C")),
            ],
            suggestedOrder: 3
        ),
        Song(
            id: "row-row-row-your-boat",
            title: "Row, Row, Row Your Boat",
            bpm: 110,
            sections: [
                SongSection(name: "Verse", patternID: "upbeat",
                            bars: bars("G G C D | G G C D")),
                SongSection(name: "Chorus", patternID: "upbeat",
                            bars: bars("G G C D | G G C D | G G C G")),
            ],
            suggestedOrder: 4
        ),
        Song(
            id: "down-by-the-riverside",
            title: "Down by the Riverside",
            bpm: 100,
            sections: [
                SongSection(name: "Verse", patternID: "driving",
                            bars: bars("G G D G | G G D G")),
                SongSection(name: "Chorus", patternID: "driving",
                            bars: bars("C G D G | C G D G | C G D G | C G D G")),
            ],
            suggestedOrder: 5
        ),
    ]

    var songs: [Song] { Self.all }

    static func song(forID id: String) -> Song? {
        all.first { $0.id == id }
    }

    /// "C C F C | G G" -> six bars. The "|" is only for reading.
    private static func bars(_ text: String) -> [SongBar] {
        text.split(whereSeparator: { $0 == " " || $0 == "|" })
            .map { SongBar(chord: String($0)) }
    }
}
