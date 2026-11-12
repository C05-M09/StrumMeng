import Foundation

/// The 5 Showtime songs. All are public domain, with no lyrics.
/// Order requested by user:
/// 1. twinkle-twinkle, 2. jingle bells, 3. abc, 4. row row row your boat, 5. down by the riverside
struct DefaultSongCatalog: SongCatalog {
    static let allowedChords: Set<String> = ["C", "F", "G", "Em", "D", "Am", "A7", "D7", "G7"]

    static let all: [Song] = [
        Song(
            id: "twinkle-twinkle",
            title: "Twinkle Twinkle Little Star",
            // The bundled recording is 80 BPM (beat-grid fit), so the nodes follow the song.
            bpm: 80,
            patternID: "foundation",
            barCount: 12,
            chords: [
                SongChordChange(slot: 0, chord: "C"),
                SongChordChange(slot: 8, chord: "F"),
                SongChordChange(slot: 12, chord: "C"),
                SongChordChange(slot: 16, chord: "F"),
                SongChordChange(slot: 20, chord: "C"),
                SongChordChange(slot: 24, chord: "G"),
                SongChordChange(slot: 28, chord: "C"),
                SongChordChange(slot: 32, chord: "C"),
                SongChordChange(slot: 36, chord: "F"),
                SongChordChange(slot: 40, chord: "C"),
                SongChordChange(slot: 44, chord: "G"),
                SongChordChange(slot: 48, chord: "C"),
                SongChordChange(slot: 52, chord: "F"),
                SongChordChange(slot: 56, chord: "C"),
                SongChordChange(slot: 60, chord: "G"),
                SongChordChange(slot: 64, chord: "C"),
                SongChordChange(slot: 72, chord: "F"),
                SongChordChange(slot: 76, chord: "C"),
                SongChordChange(slot: 80, chord: "F"),
                SongChordChange(slot: 84, chord: "C"),
                SongChordChange(slot: 88, chord: "G"),
                SongChordChange(slot: 92, chord: "C"),
            ],
            suggestedOrder: 1
        ),
        Song(
            id: "jingle-bells",
            title: "Jingle Bells",
            bpm: 120,
            patternID: "subdivision",
            barCount: 16,
            chords: [
                SongChordChange(slot: 0, chord: "G"),
                SongChordChange(slot: 8, chord: "G"),
                SongChordChange(slot: 16, chord: "C"),
                SongChordChange(slot: 24, chord: "G"),
                SongChordChange(slot: 32, chord: "C"),
                SongChordChange(slot: 40, chord: "G"),
                SongChordChange(slot: 48, chord: "A7"),
                SongChordChange(slot: 56, chord: "D7"),
                SongChordChange(slot: 64, chord: "G"),
                SongChordChange(slot: 72, chord: "G"),
                SongChordChange(slot: 80, chord: "C"),
                SongChordChange(slot: 88, chord: "G"),
                SongChordChange(slot: 96, chord: "C"),
                SongChordChange(slot: 104, chord: "G"),
                SongChordChange(slot: 112, chord: "D7"),
                SongChordChange(slot: 120, chord: "G"),
            ],
            suggestedOrder: 2
        ),
        Song(
            id: "abc-song",
            title: "ABC Song",
            bpm: 100,
            patternID: "syncopation",
            barCount: 12,
            chords: [
                SongChordChange(slot: 0, chord: "C"),
                SongChordChange(slot: 8, chord: "F"),
                SongChordChange(slot: 12, chord: "C"),
                SongChordChange(slot: 16, chord: "F"),
                SongChordChange(slot: 20, chord: "C"),
                SongChordChange(slot: 24, chord: "G7"),
                SongChordChange(slot: 28, chord: "C"),
                SongChordChange(slot: 32, chord: "C"),
                SongChordChange(slot: 36, chord: "F"),
                SongChordChange(slot: 38, chord: "C"),
                SongChordChange(slot: 40, chord: "C"),
                SongChordChange(slot: 44, chord: "G"),
                SongChordChange(slot: 48, chord: "C"),
                SongChordChange(slot: 52, chord: "F"),
                SongChordChange(slot: 54, chord: "C"),
                SongChordChange(slot: 56, chord: "G"),
                SongChordChange(slot: 64, chord: "C"),
                SongChordChange(slot: 72, chord: "F"),
                SongChordChange(slot: 76, chord: "C"),
                SongChordChange(slot: 80, chord: "F"),
                SongChordChange(slot: 84, chord: "C"),
                SongChordChange(slot: 88, chord: "G7"),
                SongChordChange(slot: 92, chord: "C"),
            ],
            suggestedOrder: 3
        ),
        Song(
            id: "row-row-row-your-boat",
            title: "Row, Row, Row Your Boat",
            bpm: 110,
            patternID: "upbeat",
            barCount: 4,
            chords: [
                SongChordChange(slot: 0, chord: "G"),
                SongChordChange(slot: 8, chord: "G"),
                SongChordChange(slot: 16, chord: "C"),
                SongChordChange(slot: 20, chord: "G"),
                SongChordChange(slot: 24, chord: "D"),
                SongChordChange(slot: 28, chord: "G"),
            ],
            suggestedOrder: 4
        ),
        Song(
            id: "down-by-the-riverside",
            title: "Down by the Riverside",
            bpm: 100,
            patternID: "driving",
            barCount: 16,
            chords: [
                SongChordChange(slot: 0, chord: "G"),
                SongChordChange(slot: 8, chord: "G"),
                SongChordChange(slot: 16, chord: "D7"),
                SongChordChange(slot: 24, chord: "G"),
                SongChordChange(slot: 32, chord: "G"),
                SongChordChange(slot: 40, chord: "G"),
                SongChordChange(slot: 48, chord: "D"),
                SongChordChange(slot: 52, chord: "D7"),
                SongChordChange(slot: 54, chord: "G"),
                SongChordChange(slot: 56, chord: "G"),
                SongChordChange(slot: 64, chord: "C"),
                SongChordChange(slot: 72, chord: "G"),
                SongChordChange(slot: 80, chord: "D"),
                SongChordChange(slot: 84, chord: "D7"),
                SongChordChange(slot: 86, chord: "G"),
                SongChordChange(slot: 88, chord: "G"),
                SongChordChange(slot: 96, chord: "C"),
                SongChordChange(slot: 104, chord: "G"),
                SongChordChange(slot: 112, chord: "D"),
                SongChordChange(slot: 116, chord: "D7"),
                SongChordChange(slot: 118, chord: "G"),
                SongChordChange(slot: 120, chord: "G"),
            ],
            suggestedOrder: 5
        ),
    ]

    var songs: [Song] { Self.all }

    static func song(forID id: String) -> Song? {
        all.first { $0.id == id }
    }
}
