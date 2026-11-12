import AVFoundation

@MainActor
final class AVShowtimeSongPlayer: ShowtimeSongPlayer {
    private var currentPlayer: AVAudioPlayer?
    private(set) var currentSongID: String?
    private let bundle: Bundle
    private(set) var volume: Double = VolumeConfig.defaultVolume

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    var isPlaying: Bool {
        currentPlayer?.isPlaying ?? false
    }

    func playSong(id: String) {
        if currentSongID == id && currentPlayer?.isPlaying == true {
            return
        }
        stop()
        guard let resourceName = ShowtimeAssets.audioResource(forSongID: id),
              let url = findAudioURL(resourceName: resourceName)
        else {
            return
        }
        do {
            Self.usePlaybackSession()
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Float(volume)
            player.prepareToPlay()
            player.play()
            currentPlayer = player
            currentSongID = id
        } catch {
            currentPlayer = nil
            currentSongID = nil
        }
    }

    private func findAudioURL(resourceName: String) -> URL? {
        if let url = bundle.url(forResource: resourceName, withExtension: "mp3") {
            return url
        }
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "mp3") {
            return url
        }
        for b in Bundle.allBundles + Bundle.allFrameworks {
            if let url = b.url(forResource: resourceName, withExtension: "mp3") {
                return url
            }
        }
        return nil
    }

    func stop() {
        currentPlayer?.stop()
        currentPlayer = nil
        currentSongID = nil
    }

    func pause() {
        currentPlayer?.pause()
    }

    func resume() {
        guard let currentPlayer, !currentPlayer.isPlaying else { return }
        Self.usePlaybackSession()
        currentPlayer.play()
    }

    func setVolume(_ volume: Double) {
        self.volume = VolumeConfig.clamped(volume)
        currentPlayer?.volume = Float(self.volume)
    }

    private static func usePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        guard session.category != .playback else { return }
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}

