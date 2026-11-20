import AVFoundation

/// Plays a song's mp3 under Showtime gameplay through its own AVAudioEngine. The file is scheduled
/// sample-accurately on the host clock, the same clock as the beat clock, the strums and the
/// metronome, so bar 1 sounds exactly on node 1.
///
/// The file plays untouched, at full level, exactly as the song-list preview plays it: no gain or
/// limiter, which squashed the plucks of the recordings. The one exception is the ending of a
/// recording longer than its chart: its last bar is faded into silence ahead of time and scheduled
/// right after the rest, so the fade and the stop land exactly on the nodes, with no timer.
/// Its level does not follow the app's music or sound settings: the player sets it with the
/// device's volume buttons, like any song.
@MainActor
final class AVSongBackingTrack: SongBackingTrack {
    private let bundle: Bundle
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var file: AVAudioFile?
    private var info: SongBackingTrackInfo?
    /// The fading part of the recording, from the start of the fade to the last node, already faded.
    private var fade: (buffer: AVAudioPCMBuffer, firstFrame: AVAudioFramePosition)?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        engine.attach(player)
    }

    func prepare(songID: String, ending: SongBackingTrackEnding?) {
        stop()
        fade = nil
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
        // A looped song keeps its natural decay at the end of the last loop instead.
        if info.fadesOutAtChartEnd, info.loop == nil, let ending {
            fade = Self.fadedEnding(of: file, info: info, ending: ending)
        }
    }

    func play(fromSongTime songTime: TimeInterval, atHostTime hostTime: TimeInterval) {
        guard let file, let info else { return }
        if let fade {
            playFading(file, info: info, fade: fade, fromSongTime: songTime, atHostTime: hostTime)
            return
        }
        let sampleRate = file.processingFormat.sampleRate
        let segments = info.segments(fromSongTime: songTime, atHostTime: hostTime,
                                     fileDuration: Double(file.length) / sampleRate)
        guard !segments.isEmpty, ensureRunning() else { return }
        // Replacing the queue on every start/resume prevents duplicate playback after a pause.
        player.stop()
        for segment in segments {
            let firstFrame = AVAudioFramePosition((segment.filePosition * sampleRate).rounded())
            let lastFrame = min(file.length,
                AVAudioFramePosition(((segment.filePosition + segment.duration) * sampleRate).rounded()))
            guard lastFrame > firstFrame else { continue }
            player.scheduleSegment(file, startingFrame: firstFrame,
                                   frameCount: AVAudioFrameCount(lastFrame - firstFrame),
                                   at: AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: segment.hostTime)),
                                   completionHandler: nil)
        }
        player.play()
    }

    /// A song that fades out at the end of its chart (never a looped one): full level up to the
    /// fade, then the faded bar straight after it (at: nil) on the same timeline, silent on the last
    /// node. Resuming inside the fade plays only the rest of it.
    private func playFading(_ file: AVAudioFile, info: SongBackingTrackInfo,
                            fade: (buffer: AVAudioPCMBuffer, firstFrame: AVAudioFramePosition),
                            fromSongTime songTime: TimeInterval, atHostTime hostTime: TimeInterval) {
        let start = info.start(fromSongTime: songTime, atHostTime: hostTime)
        let firstFrame = Self.frame(start.filePosition, file.processingFormat.sampleRate)
        let lastFrame = fade.firstFrame + AVAudioFramePosition(fade.buffer.frameLength)
        guard firstFrame < lastFrame, ensureRunning() else { return }
        // Stopping drops anything still scheduled from an earlier start.
        player.stop()
        let when = AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: start.hostTime))
        var fadeTime: AVAudioTime? = when
        if firstFrame < fade.firstFrame {
            player.scheduleSegment(file, startingFrame: firstFrame,
                                   frameCount: AVAudioFrameCount(fade.firstFrame - firstFrame),
                                   at: when, completionHandler: nil)
            fadeTime = nil
        }
        let offset = max(0, firstFrame - fade.firstFrame)
        if let rest = Self.slice(fade.buffer, from: AVAudioFrameCount(offset)) {
            player.scheduleBuffer(rest, at: fadeTime, options: [], completionHandler: nil)
        }
        player.play()
    }

    func stop() {
        player.stop()
    }

    private static func frame(_ seconds: TimeInterval, _ rate: Double) -> AVAudioFramePosition {
        AVAudioFramePosition(max(0, seconds) * rate)
    }

    /// Reads the recording from the start of the fade to the last node and applies the fade to it.
    /// Done once in prepare, before anything plays, so it never competes with playback for the file.
    private static func fadedEnding(of file: AVAudioFile, info: SongBackingTrackInfo,
                                    ending: SongBackingTrackEnding) -> (AVAudioPCMBuffer, AVAudioFramePosition)? {
        let rate = file.processingFormat.sampleRate
        let first = min(file.length, frame(info.filePosition(atSongTime: ending.fadeStart), rate))
        let last = min(file.length, frame(info.filePosition(atSongTime: ending.end), rate))
        guard last > first,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(last - first)) else { return nil }
        file.framePosition = first
        guard (try? file.read(into: buffer, frameCount: AVAudioFrameCount(last - first))) != nil,
              let channels = buffer.floatChannelData else { return nil }
        for index in 0..<Int(buffer.frameLength) {
            let songTime = Double(first + AVAudioFramePosition(index)) / rate - info.firstBeat
            let gain = Float(ending.gain(atSongTime: songTime))
            for channel in 0..<Int(buffer.format.channelCount) {
                channels[channel][index] *= gain
            }
        }
        return (buffer, first)
    }

    /// The buffer from `start` on, or nil when nothing is left.
    private static func slice(_ buffer: AVAudioPCMBuffer, from start: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard start < buffer.frameLength else { return nil }
        guard start > 0 else { return buffer }
        let count = buffer.frameLength - start
        guard let rest = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: count),
              let source = buffer.floatChannelData, let target = rest.floatChannelData else { return nil }
        rest.frameLength = count
        for channel in 0..<Int(buffer.format.channelCount) {
            target[channel].update(from: source[channel].advanced(by: Int(start)), count: Int(count))
        }
        return rest
    }

    /// The guitar engine set up the shared session (.playback); this only makes sure it is active.
    private func ensureRunning() -> Bool {
        guard !engine.isRunning else { return true }
        try? AVAudioSession.sharedInstance().setActive(true)
        do { try engine.start() } catch { return false }
        return true
    }
}
