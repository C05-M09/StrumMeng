import AVFoundation

extension Notification.Name {
    static let listenAudioInterrupted = AVAudioSession.interruptionNotification
}

/// Renders one bar from the supplied guitar samples, then loops it on the audio sample clock.
@MainActor
final class GuitarListenPlayer: ListenPatternPlayer {
    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()

    init() {
        engine.attach(node)
    }

    var elapsed: TimeInterval {
        guard let render = node.lastRenderTime,
              let time = node.playerTime(forNodeTime: render) else { return 0 }
        return Double(time.sampleTime) / time.sampleRate
    }

    func start(pattern: StrumPattern, bpm: Int) throws {
        stop()
        guard bpm > 0, pattern.beatsPerPattern > 0, !pattern.strokes.isEmpty else {
            throw PlaybackError.invalidPattern
        }
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        let down = try sample(named: "Listen_Down_3")
        let up = try sample(named: "Listen_Up_Extracted")
        let rate = down.format.sampleRate
        guard up.format.sampleRate == rate else { throw PlaybackError.invalidSample }
        let duration = Double(pattern.beatsPerPattern) * 60 / Double(bpm)
        let frames = AVAudioFrameCount((duration * rate).rounded())
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: down.format, frameCapacity: frames),
              let output = buffer.floatChannelData?[0] else { throw PlaybackError.invalidSample }
        buffer.frameLength = frames
        output.initialize(repeating: 0, count: Int(frames))
        for (index, stroke) in pattern.strokes.enumerated() where stroke != .rest {
            let source = stroke == .down ? down : up
            guard let samples = source.floatChannelData?[0] else { throw PlaybackError.invalidSample }
            let count = Int(source.frameLength)
            // Remove leading silence only; preserve the attack and the guitar's natural decay.
            let onset = (0..<count).first { abs(samples[$0]) > 0.012 } ?? 0
            let length = min(count - onset, Int(rate * 2))
            let offset = Int((Double(index) * Double(frames) / Double(pattern.strokes.count)).rounded())
            for frame in 0..<length {
                let fade = min(1, Double(length - frame) / (rate * 0.025))
                output[(offset + frame) % Int(frames)] += samples[onset + frame] * Float(fade)
            }
        }
        let peak = (0..<Int(frames)).reduce(Float(1)) { max($0, abs(output[$1])) }
        for frame in 0..<Int(frames) { output[frame] *= 0.85 / peak }
        engine.disconnectNodeOutput(node)
        engine.connect(node, to: engine.mainMixerNode, format: buffer.format)
        try engine.start()
        node.scheduleBuffer(buffer, at: nil, options: .loops)
        node.play()
    }

    func pause() { node.pause() }
    func resume() { node.play() }
    func stop() { node.stop(); engine.stop() }

    private func sample(named name: String) throws -> AVAudioPCMBuffer {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            throw PlaybackError.missingSample
        }
        let file = try AVAudioFile(forReading: url)
        guard file.processingFormat.channelCount == 1,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(file.length)) else {
            throw PlaybackError.invalidSample
        }
        try file.read(into: buffer)
        return buffer
    }

    private enum PlaybackError: Error {
        case invalidPattern, invalidSample, missingSample
    }
}
