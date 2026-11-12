import AVFoundation

/// Plays a song's mp3 under Showtime gameplay through its own AVAudioEngine. The file is scheduled
/// sample-accurately on the host clock, the same clock as the beat clock, the strums and the
/// metronome, so bar 1 sounds exactly on node 1.
///
/// The file plays untouched, at full level, exactly as the song-list preview plays it: no gain or
/// limiter, which squashed the plucks of the recordings. Its level does not follow the app's music
/// or sound settings: the player sets it with the device's volume buttons, like any song.
@MainActor
final class AVSongBackingTrack: SongBackingTrack {
    private let bundle: Bundle
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var file: AVAudioFile?
    private var info: SongBackingTrackInfo?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        engine.attach(player)
    }

    func prepare(songID: String) {
        stop()
        guard let info = SongBackingTrackInfo.forSong(songID),
              let url = bundle.url(forResource: info.resource, withExtension: "mp3"),
              let file = try? AVAudioFile(forReading: url) else {
            self.file = nil
            self.info = nil
            return
        }
        // The file's own format: the main mixer converts to the output's sample rate.
        engine.disconnectNodeOutput(player)
        engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
        engine.prepare()
        self.file = file
        self.info = info
    }

    func play(fromSongTime songTime: TimeInterval, atHostTime hostTime: TimeInterval) {
        guard let file, let info else { return }
        let start = info.start(fromSongTime: songTime, atHostTime: hostTime)
        let firstFrame = AVAudioFramePosition(start.filePosition * file.processingFormat.sampleRate)
        guard firstFrame < file.length, ensureRunning() else { return }
        // Stopping drops anything still scheduled from an earlier start.
        player.stop()
        player.scheduleSegment(file, startingFrame: firstFrame,
                               frameCount: AVAudioFrameCount(file.length - firstFrame),
                               at: AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: start.hostTime)),
                               completionHandler: nil)
        player.play()
    }

    func stop() {
        player.stop()
    }

    /// The guitar engine set up the shared session (.playback); this only makes sure it is active.
    private func ensureRunning() -> Bool {
        guard !engine.isRunning else { return true }
        try? AVAudioSession.sharedInstance().setActive(true)
        do { try engine.start() } catch { return false }
        return true
    }
}
