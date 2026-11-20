import Foundation

/// Turns one strum into the notes of each string, as the prototype's GuitarEngine.strum did.
/// Pure: randomness is injected, so tests can fix it.
nonisolated enum StrumVoicing {
    /// Pluck strengths synthesised in advance: soft, medium, hard.
    static let layerVelocities: [Double] = [0.35, 0.65, 0.95]

    /// - Parameter accent: 0...1, how hard the whole strum is.
    static func notes(
        chord: GuitarChord,
        direction: StrumDirection,
        accent: Double,
        settings: GuitarSoundSettings,
        random: inout some RandomNumberGenerator
    ) -> [StrumNote] {
        let isDown: Bool
        switch direction {
        case .down: isDown = true
        case .up: isDown = false
        }
        let humanize = settings.humanize
        func jitter() -> Double { Double.random(in: -1...1, using: &random) }

        let order = isDown ? Array(0..<6) : Array((0..<6).reversed())
        // Upstrokes are a little quicker.
        let spread = settings.strumSpreadMs / 1000 * (isDown ? 1 : 0.85) * (1 + jitter() * 0.15 * humanize)

        var notes: [StrumNote] = []
        for (position, string) in order.enumerated() {
            let fret = chord.frets[string]
            guard fret >= 0 else { continue }
            // An upstroke seldom reaches the two bass strings.
            if !isDown, string <= 1, Double.random(in: 0...1, using: &random) > settings.upstrokeBass { continue }
            // 0...1 along the strum; muted strings still take their place in time, as on a real guitar.
            let along = Double(position) / 5
            var velocity = accent * (isDown ? 1 - 0.15 * along : 0.85 * (1 - 0.3 * along))
            velocity = min(1, max(0.12, velocity * (1 + jitter() * 0.15 * humanize)))
            let offset = max(0, spread * along + jitter() * 0.0015 * humanize)
            notes.append(StrumNote(string: string, fret: fret, velocity: velocity, offset: offset))
        }
        return notes
    }

    /// The pre-synthesised layer closest to a velocity.
    static func layer(for velocity: Double) -> Int {
        velocity < 0.5 ? 0 : (velocity < 0.8 ? 1 : 2)
    }
}
