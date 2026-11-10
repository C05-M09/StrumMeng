import Foundation

/// The metronome click from the prototype: a short sine blip that dies away in a few ms.
nonisolated enum ClickSound {
    static let duration = 0.06
    static let accentFrequency = 1760.0
    static let beatFrequency = 1175.0

    static func samples(frequency: Double, sampleRate fs: Double) -> [Float] {
        (0..<Int(fs * duration)).map { n in
            let t = Double(n) / fs
            return Float(sin(2 * .pi * frequency * t) * exp(-t / 0.012) * 0.9)
        }
    }
}
