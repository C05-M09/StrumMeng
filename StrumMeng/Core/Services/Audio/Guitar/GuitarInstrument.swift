import Foundation

/// The guitar body the synth imitates. Ported from the "test audio gitar" prototype.
nonisolated enum GuitarInstrument: Sendable, Equatable {
    case steel
    case nylon

    var preset: GuitarStringPreset {
        switch self {
        case .steel: GuitarStringPreset(t60Low: 7.5, t60High: 3.0, brightness: 0.85, pickPosition: 0.14, pickLevel: 0.20)
        case .nylon: GuitarStringPreset(t60Low: 5.0, t60High: 2.0, brightness: 0.50, pickPosition: 0.20, pickLevel: 0.09)
        }
    }
}
