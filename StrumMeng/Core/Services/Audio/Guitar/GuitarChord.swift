import Foundation

/// A chord shape: one fret per string, from low E (string 6) to high e (string 1); -1 = muted.
/// Practice never asks for a chord (CLAUDE.md §9), so it plays every strum as C. Showtime songs
/// (US12) play the song's chords from the catalog.
nonisolated struct GuitarChord: Sendable, Equatable, Hashable {
    let name: String
    let frets: [Int]

    static let c = GuitarChord(name: "C", frets: [-1, 3, 2, 0, 1, 0])
    static let g = GuitarChord(name: "G", frets: [3, 2, 0, 0, 0, 3])
    static let em = GuitarChord(name: "Em", frets: [0, 2, 2, 0, 0, 0])
    static let d = GuitarChord(name: "D", frets: [-1, -1, 0, 2, 3, 2])
    /// The full barre on the first fret, not the easier four-string F.
    static let f = GuitarChord(name: "F", frets: [1, 3, 3, 2, 1, 1])
    static let am = GuitarChord(name: "Am", frets: [-1, 0, 2, 2, 1, 0])
    /// Open dominant sevenths, as in the guitar sound prototype (G7) and common chord charts.
    static let a7 = GuitarChord(name: "A7", frets: [-1, 0, 2, 0, 2, 0])
    static let d7 = GuitarChord(name: "D7", frets: [-1, -1, 0, 2, 1, 2])
    static let g7 = GuitarChord(name: "G7", frets: [3, 2, 0, 0, 0, 1])

    /// Every chord a song can use.
    static let catalog: [GuitarChord] = [.c, .g, .em, .d, .f, .am, .a7, .d7, .g7]

    /// The catalog chord with exactly this name ("Em", not "em"), or nil.
    static func named(_ name: String) -> GuitarChord? {
        catalog.first { $0.name == name }
    }
}
