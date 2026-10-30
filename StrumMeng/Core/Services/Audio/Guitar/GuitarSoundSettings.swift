import Foundation

/// How the synth guitar sounds. Values use the prototype's slider ranges.
nonisolated struct GuitarSoundSettings: Sendable, Equatable {
    var instrument: GuitarInstrument
    /// How long a strum takes to cross the six strings.
    var strumSpreadMs: Double
    /// 0...1: random variation in timing and loudness, so repeated strums do not sound robotic.
    var humanize: Double
    /// Multiplies how long the strings ring.
    var sustain: Double
    /// 0...1; 0.5 is the instrument's own brightness.
    var brightness: Double
    /// 0...1: chance that an upstroke also hits the two bass strings.
    var upstrokeBass: Double
    /// 0...1 reverb amount.
    var reverb: Double
    /// 0...1 output volume.
    var volume: Double

    /// The team's chosen sound from the prototype: nylon, 45 ms, humanize 100, sustain 1.5,
    /// brightness 50, bass on upstrokes 30, reverb 25, volume 80.
    static let favourite = GuitarSoundSettings(
        instrument: .nylon,
        strumSpreadMs: 45,
        humanize: 1.0,
        sustain: 1.5,
        brightness: 0.5,
        upstrokeBass: 0.3,
        reverb: 0.25,
        volume: 0.8
    )
}
