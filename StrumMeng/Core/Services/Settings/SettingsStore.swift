import Foundation

/// The user's settings, shared by the whole app. View models depend on this protocol,
/// never on `UserDefaults`. `AppContainer` is the one place that wires in the real store.
///
/// The real store is `@Observable`, so audio code that reads these values reacts
/// to a slider change straight away, even while a session is playing.
@MainActor
protocol SettingsStore: AnyObject {
    /// Volume of the menu background music (the Music slider), 0...1.
    /// It first meant the metronome volume; see ARCHITECTURE.md decision 21.
    var soundVolume: Double { get }

    /// Volume of the sound effects, such as the button click (the Sound Effects slider), 0...1.
    var sfxVolume: Double { get }

    /// Saves the value. Anything outside 0...1 is clamped first.
    func setSoundVolume(_ value: Double)
    func setSFXVolume(_ value: Double)
}
