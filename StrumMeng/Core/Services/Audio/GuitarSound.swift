import Foundation

/// The synthesised guitar. The iPad plays the Listen example and the player's own strums in Play;
/// the iPhone plays its strums while no session is running.
@MainActor
protocol GuitarSound: AnyObject {
    /// Synthesises the notes of these chords ahead of time, so no strum waits for synthesis, also not
    /// when a song changes chord. Safe to call again; notes already made are kept.
    func prepare(chords: [GuitarChord]) async

    /// - Parameters:
    ///   - chord: the chord this strum sounds.
    ///   - time: when the strum starts, in HostClock seconds; nil = as soon as possible.
    ///   - accent: 0...1, how hard the strum is.
    func strum(_ direction: StrumDirection, chord: GuitarChord, at time: TimeInterval?, accent: Double)

    /// Silences every string and drops strums scheduled but not played yet.
    func stopStrums()
}

extension GuitarSound {
    /// Practice never asks for a chord (CLAUDE.md §9), so it prepares and plays C only.
    func prepare() async {
        await prepare(chords: [.c])
    }

    /// A strum of C, the chord Practice plays.
    func strum(_ direction: StrumDirection, at time: TimeInterval?, accent: Double) {
        strum(direction, chord: .c, at: time, accent: accent)
    }
}
