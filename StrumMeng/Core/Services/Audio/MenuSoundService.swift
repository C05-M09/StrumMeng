import Foundation

/// The menu background music and the button click. View models depend on this protocol;
/// `AppContainer` is the one place that wires in the real player.
///
/// Volumes are 0...1. The Option sliders set them through the Option view model, and
/// `AppContainer` sets the saved values at launch, so the service never reads SettingsStore itself.
@MainActor
protocol MenuSoundService: AnyObject {
    /// Starts the looping background music, or resumes it where it was paused.
    /// Does nothing while the music is already playing.
    func startMusic()

    /// Pauses the background music, keeping its position for the next `startMusic()`.
    func pauseMusic()

    /// Plays the button click once. A new tap restarts it, so fast taps each get a click.
    func playButtonSound()

    /// Values outside 0...1 are clamped.
    func setMusicVolume(_ volume: Double)
    func setEffectsVolume(_ volume: Double)
}
