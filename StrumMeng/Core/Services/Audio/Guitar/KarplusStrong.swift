import Foundation

/// Extended Karplus-Strong plucked string, ported from the prototype: a noise burst shaped by the
/// pick position and pluck strength circulates in a delay line whose two-point average damps the
/// highs, with an allpass for exact tuning and a per-round gain for the ring time.
nonisolated enum KarplusStrong {
    static let noteSeconds = 3.5
    /// Open strings from low E to high e: E2 A2 D3 G3 B3 E4.
    static let openMidi = [40, 45, 50, 55, 59, 64]

    /// One note as mono samples. The pluck strength is already in the output level.
    /// - Parameter random: injected so tests are repeatable.
    static func pluck(
        sampleRate fs: Double,
        midi: Int,
        velocity: Double,
        instrument: GuitarInstrument,
        sustain: Double,
        brightness: Double,
        random: inout some RandomNumberGenerator
    ) -> [Float] {
        let preset = instrument.preset
        let frequency = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
        let total = Int(fs * noteSeconds)

        // The average filter adds half a sample of delay; the allpass covers the fraction left.
        let period = fs / frequency - 0.5
        let length = Int(floor(period - 0.5))
        let fraction = period - Double(length)
        let allpass = Float((1 - fraction) / (1 + fraction))

        // Excitation: noise, a comb at the pick position, then a low-pass for how hard it is plucked.
        var noise = [Float](repeating: 0, count: length)
        for i in 0..<length { noise[i] = Float.random(in: -1...1, using: &random) }
        let pickOffset = max(1, Int((preset.pickPosition * Double(length)).rounded()))
        var line = [Float](repeating: 0, count: length)
        for i in 0..<length { line[i] = noise[i] - noise[(i - pickOffset + length) % length] }

        let bright = min(1, max(0, preset.brightness * (0.5 + brightness)))
        let alpha = Float(0.12 + 0.85 * bright * (0.3 + 0.7 * velocity))
        for _ in 0..<2 {
            var y: Float = 0
            for i in 0..<length { y += alpha * (line[i] - y); line[i] = y }
        }
        let mean = line.reduce(0, +) / Float(length)
        var peak: Float = 1e-9
        for i in 0..<length { line[i] -= mean; peak = max(peak, abs(line[i])) }
        for i in 0..<length { line[i] /= peak }

        // Low strings ring longer than high ones.
        let t60 = max(preset.t60High, preset.t60Low * pow(110.0 / frequency, 0.35)) * sustain
        let decay = Float(min(0.99995, pow(0.001, 1.0 / (t60 * frequency))))

        var out = [Float](repeating: 0, count: total)
        var index = 0
        var allpassIn: Float = 0, allpassOut: Float = 0
        var previous = line[length - 1]
        line.withUnsafeMutableBufferPointer { delay in
            out.withUnsafeMutableBufferPointer { output in
                for n in 0..<total {
                    let sample = delay[index]
                    let averaged = 0.5 * (sample + previous)
                    previous = sample
                    let tuned = allpass * averaged + allpassIn - allpass * allpassOut
                    allpassIn = averaged
                    allpassOut = tuned
                    delay[index] = decay * tuned
                    output[n] = sample
                    index += 1
                    if index == length { index = 0 }
                }
            }
        }

        // The pick's own click at the start.
        let pickSamples = min(Int(fs * 0.012), total)
        for n in 0..<pickSamples {
            let envelope = Float(preset.pickLevel * velocity * exp(-Double(n) / (fs * 0.002)))
            out[n] += Float.random(in: -1...1, using: &random) * envelope
        }
        // Fade the tail so the note never ends with a click.
        let fade = Int(fs * 0.25)
        for n in 0..<fade { out[total - 1 - n] *= Float(n) / Float(fade) }
        let gain = Float(0.3 * (0.25 + 0.75 * velocity))
        for n in 0..<total { out[n] *= gain }
        return out
    }
}
