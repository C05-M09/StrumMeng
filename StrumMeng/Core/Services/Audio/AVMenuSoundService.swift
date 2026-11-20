import AVFoundation

/// Plays the menu music and the sound effects from the bundled audio files with `AVAudioPlayer`.
///
/// A missing or unreadable file leaves that sound silent: the app keeps working without it.
/// It shares the app's `.playback` audio session with the guitar engine, so both mix.
@MainActor
final class AVMenuSoundService: MenuSoundService {
    /// The audio files to load, by name and extension.
    nonisolated struct Files {
        /// nil plays no music (the iPhone controller).
        let musicName: String?
        let musicExtension: String
        let effects: [SoundEffect: String]
        let effectsExtension: String

        /// The sounds in Resources/Audio.
        static let bundled = Files(
            musicName: "Background_MSC",
            musicExtension: "mp3",
            effects: [
                .button: "Button_SFX",
                .garage: "Garage_SFX",
                .guidebookPage: "Guidebook_Page_SFX",
                .popUp: "Popup_SFX",
                .wheelTick: "Wheel_Tick_SFX"
            ],
            effectsExtension: "mp3"
        )

        /// The iPhone controller: only the button click, no music.
        static let controller = Files(
            musicName: nil,
            musicExtension: "mp3",
            effects: [.button: "Button_SFX"],
            effectsExtension: "mp3"
        )
    }

    /// How many copies of an effect can sound at once. A fast wheel spin ticks faster than the
    /// tick lasts, and fast taps should not cut each other off; one copy is enough for the rest.
    static func voiceCount(for effect: SoundEffect) -> Int {
        switch effect {
        case .wheelTick: 4
        case .button: 2
        case .garage, .guidebookPage, .popUp: 1
        }
    }

    private let music: AVAudioPlayer?
    /// Each effect's copies, used round-robin.
    private var effectVoices: [SoundEffect: [AVAudioPlayer]] = [:]
    private var nextVoice: [SoundEffect: Int] = [:]

    private(set) var musicVolume = VolumeConfig.defaultVolume
    private(set) var effectsVolume = VolumeConfig.defaultVolume

    init(bundle: Bundle = .main, files: Files = .bundled) {
        music = files.musicName.flatMap {
            Self.makePlayer(bundle: bundle, name: $0, fileExtension: files.musicExtension)
        }
        music?.numberOfLoops = -1  // loop until paused
        music?.prepareToPlay()

        for (effect, name) in files.effects {
            let voices = (0..<Self.voiceCount(for: effect)).compactMap { _ in
                Self.makePlayer(bundle: bundle, name: name, fileExtension: files.effectsExtension)
            }
            voices.forEach { $0.prepareToPlay() }
            effectVoices[effect] = voices.isEmpty ? nil : voices
        }
        applyVolumes()
    }

    var hasMusic: Bool { music != nil }

    func hasSound(for effect: SoundEffect) -> Bool { effectVoices[effect] != nil }

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

    func play(_ effect: SoundEffect) {
        guard let voices = effectVoices[effect], effectsVolume > 0 else { return }
        let index = nextVoice[effect, default: 0] % voices.count
        nextVoice[effect] = index + 1
        Self.usePlaybackSession()
        let voice = voices[index]
        voice.currentTime = 0
        voice.play()
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
        for voice in effectVoices.values.joined() {
            voice.volume = Float(effectsVolume)
        }
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
