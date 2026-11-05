import AVFoundation

/// Plays the menu music and the button click from the bundled audio files with `AVAudioPlayer`.
///
/// A missing or unreadable file leaves that sound silent: the app keeps working without it.
/// It shares the app's `.playback` audio session with the guitar engine, so both mix.
@MainActor
final class AVMenuSoundService: MenuSoundService {
    /// The audio files to load, by name and extension.
    struct Files {
        let musicName: String
        let musicExtension: String
        let buttonName: String
        let buttonExtension: String

        /// The placeholder sounds in Resources/Audio (M09-153).
        static let bundled = Files(
            musicName: "Background_MSC",
            musicExtension: "mp3",
            buttonName: "Button_SFX",
            buttonExtension: "wav"
        )
    }

    private let music: AVAudioPlayer?
    private let button: AVAudioPlayer?

    private(set) var musicVolume = VolumeConfig.defaultVolume
    private(set) var effectsVolume = VolumeConfig.defaultVolume

    init(bundle: Bundle = .main, files: Files = .bundled) {
        music = Self.makePlayer(bundle: bundle, name: files.musicName, fileExtension: files.musicExtension)
        button = Self.makePlayer(bundle: bundle, name: files.buttonName, fileExtension: files.buttonExtension)

        music?.numberOfLoops = -1  // loop until paused
        music?.prepareToPlay()
        button?.prepareToPlay()
        applyVolumes()
    }

    var hasMusic: Bool { music != nil }
    var hasButtonSound: Bool { button != nil }

    /// Read from the player, so a pause by the system (a phone call) shows here too
    /// and the next `startMusic()` resumes it.
    var isMusicPlaying: Bool { music?.isPlaying ?? false }

    // MARK: MenuSoundService

    func startMusic() {
        guard let music, !music.isPlaying else { return }
        Self.usePlaybackSession()
        music.play()
    }

    func pauseMusic() {
        music?.pause()
    }

    func playButtonSound() {
        guard let button, effectsVolume > 0 else { return }
        Self.usePlaybackSession()
        button.currentTime = 0
        button.play()
    }

    func setMusicVolume(_ volume: Double) {
        musicVolume = VolumeConfig.clamped(volume)
        applyVolumes()
    }

    func setEffectsVolume(_ volume: Double) {
        effectsVolume = VolumeConfig.clamped(volume)
        applyVolumes()
    }

    // MARK: private

    private func applyVolumes() {
        music?.volume = Float(musicVolume)
        button?.volume = Float(effectsVolume)
    }

    private static func makePlayer(bundle: Bundle, name: String, fileExtension: String) -> AVAudioPlayer? {
        guard let url = bundle.url(forResource: name, withExtension: fileExtension) else { return nil }
        return try? AVAudioPlayer(contentsOf: url)
    }

    /// The guitar engine normally sets `.playback` at launch. This covers the case where it has not
    /// been created yet, without touching a session that is already set up.
    private static func usePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        guard session.category != .playback else { return }
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }
}
