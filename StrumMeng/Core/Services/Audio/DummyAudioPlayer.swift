#if DEBUG
import AVFoundation
import Observation

/// DEBUG ONLY. A stand-in for the real metronome / PatternPlayer / sound effects, which do not exist yet.
/// It makes its own sounds in code (no audio files), so you can hear the Option sliders working:
/// - a looping "sound" (a soft chord), volume = Sound slider
/// - a short "effect" (a blip), volume = Sound Effects slider
/// Delete this file when the real audio services are wired to `SettingsStore`.
@MainActor
@Observable
final class DummyAudioPlayer {
    private(set) var isMusicPlaying = false

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let musicNode = AVAudioPlayerNode()
    @ObservationIgnored private let effectNode = AVAudioPlayerNode()
    @ObservationIgnored private let musicBuffer: AVAudioPCMBuffer
    @ObservationIgnored private let effectBuffer: AVAudioPCMBuffer

    /// Returns nil if the audio format or the buffers cannot be created.
    init?() {
        guard
            let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1),
            let music = Self.makeBuffer(format: format, duration: 2.0, frequencies: [220, 277.5, 330], decay: nil),
            let effect = Self.makeBuffer(format: format, duration: 0.35, frequencies: [880], decay: 12)
        else { return nil }

        musicBuffer = music
        effectBuffer = effect

        engine.attach(musicNode)
        engine.attach(effectNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        engine.connect(effectNode, to: engine.mainMixerNode, format: format)
    }

    // MARK: volume (0...1, linear). Call whenever the slider moves.

    func setSoundVolume(_ value: Double) {
        musicNode.volume = Float(VolumeConfig.clamped(value))
    }

    func setSFXVolume(_ value: Double) {
        effectNode.volume = Float(VolumeConfig.clamped(value))
    }

    // MARK: playback

    func startMusic() {
        guard prepareEngine() else { return }
        musicNode.stop()
        musicNode.scheduleBuffer(musicBuffer, at: nil, options: .loops)
        musicNode.play()
        isMusicPlaying = true
    }

    func stopMusic() {
        musicNode.stop()
        isMusicPlaying = false
    }

    func playEffect() {
        guard prepareEngine() else { return }
        effectNode.stop()
        effectNode.scheduleBuffer(effectBuffer, at: nil, options: [])
        effectNode.play()
    }

    // MARK: private

    private func prepareEngine() -> Bool {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            return false
        }
        #endif
        guard !engine.isRunning else { return true }
        do {
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    private static let sampleRate = 44_100.0

    /// A mono buffer of summed sine waves. Frequencies are multiples of 1/duration, so the loop is seamless.
    /// `decay` makes the sound fade out quickly (for the effect); nil keeps it steady (for the loop).
    private static func makeBuffer(
        format: AVAudioFormat,
        duration: Double,
        frequencies: [Double],
        decay: Double?
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let samples = buffer.floatChannelData?[0]
        else { return nil }

        buffer.frameLength = frameCount
        for index in 0..<Int(frameCount) {
            let time = Double(index) / sampleRate
            var value = 0.0
            for frequency in frequencies {
                value += sin(2 * .pi * frequency * time)
            }
            value /= Double(frequencies.count)
            if let decay { value *= exp(-decay * time) }
            samples[index] = Float(value * 0.8)
        }
        return buffer
    }
}
#endif
