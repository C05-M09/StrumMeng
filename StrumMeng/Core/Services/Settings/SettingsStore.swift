import Foundation

/// The user's settings, shared by the whole app. View models depend on this protocol,
/// never on `UserDefaults`. `AppContainer` is the one place that wires in the real store.
///
/// The real store is `@Observable`, so audio code that reads these values reacts
/// to a slider change straight away, even while a session is playing.
@MainActor
protocol SettingsStore: AnyObject {
    /// Volume of the metronome and the pattern example, 0...1.
    var soundVolume: Double { get }

    /// Volume of the sound effects, 0...1.
    var sfxVolume: Double { get }

    /// Saves the value. Anything outside 0...1 is clamped first.
    func setSoundVolume(_ value: Double)
    func setSFXVolume(_ value: Double)
}
