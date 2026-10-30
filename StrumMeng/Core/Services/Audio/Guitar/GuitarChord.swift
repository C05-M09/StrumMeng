import Foundation

/// A chord shape: one fret per string, from low E (string 6) to high e (string 1); -1 = muted.
/// Practice never asks for a chord (CLAUDE.md §9), so the app plays every strum as C.
nonisolated struct GuitarChord: Sendable, Equatable {
    let name: String
    let frets: [Int]

    static let c = GuitarChord(name: "C", frets: [-1, 3, 2, 0, 1, 0])
}
