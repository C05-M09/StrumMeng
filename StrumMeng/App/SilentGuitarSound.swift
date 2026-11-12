import Foundation

/// Stands in when the audio engine could not be made, so Listen and Play still work, silently.
final class SilentGuitarSound: GuitarSound, MetronomeSound {
    func prepare(chords: [GuitarChord]) async {}
    func strum(_ direction: StrumDirection, chord: GuitarChord, at time: TimeInterval?, accent: Double) {}
    func stopStrums() {}
    func click(at time: TimeInterval, accent: Bool) {}
    func cancelClicks() {}
}
