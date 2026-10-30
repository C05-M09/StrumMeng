import Foundation

/// How one kind of string rings, for KarplusStrong.
nonisolated struct GuitarStringPreset: Sendable, Equatable {
    /// Seconds to fade by 60 dB on the lowest string.
    let t60Low: Double
    /// The shortest ring time, reached on the high strings.
    let t60High: Double
    /// Base brightness of the pluck, 0...1.
    let brightness: Double
    /// Where the pick hits the string, as a fraction of its length.
    let pickPosition: Double
    /// Loudness of the pick noise at the start of a note.
    let pickLevel: Double
}
