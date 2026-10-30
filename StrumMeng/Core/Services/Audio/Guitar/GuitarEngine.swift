import AVFoundation

/// The synthesised guitar and metronome, ported from the prototype's GuitarEngine: six player
/// nodes (one per string) → mixer → guitar-body EQ → reverb → limiter → output, plus a click
/// player straight to the output. Notes are synthesised once (KarplusStrong) and cached; strums and
/// clicks are scheduled sample-accurately on the host clock, the same clock as AudioBeatClock.
///
/// One instance for the whole app, so Listen and Play never fight over the audio session.
@MainActor
final class GuitarEngine: GuitarSound, MetronomeSound {
    /// Two takes of every note, picked at random, so repeated strums do not sound identical.
    private static let variants = 2
    /// A strum with no time is scheduled this far ahead, so its first string is not cut short.
    private static let immediateLead: TimeInterval = 0.015

    private let settings: GuitarSoundSettings
    private let chord: GuitarChord
    private let engine = AVAudioEngine()
    private let players: [AVAudioPlayerNode] = (0..<6).map { _ in AVAudioPlayerNode() }
    private let stringMixer = AVAudioMixerNode()
    private let bodyEQ = AVAudioUnitEQ(numberOfBands: 5)
    private let reverb = AVAudioUnitReverb()
    // Many ringing strings at once may peak; the limiter keeps them loud without clipping.
    private let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
        componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter,
        componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
    private let clickPlayer = AVAudioPlayerNode()
    private let sampleRate: Double
    private let format: AVAudioFormat
    private var accentClick: AVAudioPCMBuffer?
    private var beatClick: AVAudioPCMBuffer?
    private var notes: [NoteKey: AVAudioPCMBuffer] = [:]
    private var preparing: Task<Void, Never>?
    private var observers: [Task<Void, Never>] = []

    private struct NoteKey: Hashable {
        let string: Int
        let fret: Int
        let layer: Int
        let variant: Int
    }

    /// nil if the audio format cannot be made; the app then runs silent instead of crashing.
    init?(settings: GuitarSoundSettings = .favourite, chord: GuitarChord = .c) {
        let session = AVAudioSession.sharedInstance()
        do {
            // .playback keeps sounding with the silent switch on.
            try session.setCategory(.playback, mode: .default)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            // Still usable with the default session; strums may just have more output latency.
        }
        let rate = session.sampleRate > 0 ? session.sampleRate : 48_000
        guard let mono = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1) else { return nil }
        self.settings = settings
        self.chord = chord
        sampleRate = rate
        format = mono

        buildGraph()
        start()
        observeAudioChanges()
    }

    // MARK: GuitarSound

    func prepare() async {
        if let preparing { return await preparing.value }
        let wanted = noteKeys().filter { notes[$0] == nil }
        let (rate, settings, chord) = (sampleRate, settings, chord)
        let task = Task { [weak self] in
            // Synthesis is pure and slow-ish, so it runs off the main actor.
            let rendered = await Task.detached(priority: .userInitiated) {
                var random = SystemRandomNumberGenerator()
                return wanted.map { key in
                    (key, Self.render(key, chord: chord, settings: settings, sampleRate: rate, random: &random))
                }
            }.value
            guard let self else { return }
            for (key, samples) in rendered where self.notes[key] == nil {
                self.notes[key] = self.makeBuffer(samples)
            }
        }
        preparing = task
        await task.value
    }

    func strum(_ direction: StrumDirection, at time: TimeInterval?, accent: Double) {
        ensureRunning()
        let start = time ?? HostClock.now() + Self.immediateLead
        var random = SystemRandomNumberGenerator()
        let voiced = StrumVoicing.notes(chord: chord, direction: direction, accent: accent,
                                        settings: settings, random: &random)
        for note in voiced {
            let key = NoteKey(string: note.string, fret: note.fret,
                              layer: StrumVoicing.layer(for: note.velocity),
                              variant: Int.random(in: 0..<Self.variants))
            guard let buffer = buffer(for: key) else { continue }
            // .interrupts: a new pluck on the same string cuts the old note, like a real guitar.
            players[note.string].scheduleBuffer(buffer, at: Self.audioTime(start + note.offset),
                                                options: .interrupts, completionHandler: nil)
        }
    }

    func stopStrums() {
        // Stopping a player drops what it has scheduled; play() again so the next strum sounds.
        for player in players {
            player.stop()
            player.play()
        }
    }

    // MARK: MetronomeSound

    func click(at time: TimeInterval, accent: Bool) {
        ensureRunning()
        guard let buffer = accent ? accentClick : beatClick else { return }
        clickPlayer.scheduleBuffer(buffer, at: Self.audioTime(time), options: [], completionHandler: nil)
    }

    func cancelClicks() {
        clickPlayer.stop()
        clickPlayer.play()
    }

    // MARK: Graph

    private func buildGraph() {
        engine.attach(stringMixer)
        engine.attach(bodyEQ)
        engine.attach(reverb)
        engine.attach(limiter)
        engine.attach(clickPlayer)

        for (index, player) in players.enumerated() {
            engine.attach(player)
            engine.connect(player, to: stringMixer, format: format)
            // Bass strings a little to the left, treble to the right.
            player.pan = Float((Double(index) - 2.5) / 2.5 * 0.3)
        }

        // Body resonances of an acoustic guitar: air (~95 Hz), top plate (~200 Hz) and so on.
        let resonances: [(frequency: Float, gain: Float, q: Float)] = [(95, 4, 3), (200, 3, 4), (400, -2, 2.5), (2800, 2, 1.2)]
        for (index, resonance) in resonances.enumerated() {
            let band = bodyEQ.bands[index]
            band.filterType = .parametric
            band.frequency = resonance.frequency
            band.gain = resonance.gain
            band.bandwidth = 2 * asinh(1 / (2 * resonance.q)) / log(2 as Float)
            band.bypass = false
        }
        let shelf = bodyEQ.bands[4]
        shelf.filterType = .highShelf
        shelf.frequency = 6500
        shelf.gain = -2
        shelf.bypass = false

        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = Float(settings.reverb * 60)
        // About +10 dB at the favourite volume; the limiter holds the peaks.
        stringMixer.outputVolume = Float(settings.volume * settings.volume * 3)

        engine.connect(stringMixer, to: bodyEQ, format: nil)
        engine.connect(bodyEQ, to: reverb, format: nil)
        engine.connect(reverb, to: limiter, format: nil)
        engine.connect(limiter, to: engine.mainMixerNode, format: nil)

        // The metronome skips the guitar's EQ and reverb.
        engine.connect(clickPlayer, to: engine.mainMixerNode, format: format)
        clickPlayer.volume = 0.3
        accentClick = makeBuffer(ClickSound.samples(frequency: ClickSound.accentFrequency, sampleRate: sampleRate))
        beatClick = makeBuffer(ClickSound.samples(frequency: ClickSound.beatFrequency, sampleRate: sampleRate))
    }

    private func start() {
        engine.prepare()
        do { try engine.start() } catch { return }
        players.forEach { $0.play() }
        clickPlayer.play()
    }

    private func ensureRunning() {
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            try? engine.start()
        }
        for player in players where !player.isPlaying { player.play() }
        if !clickPlayer.isPlaying { clickPlayer.play() }
    }

    private func observeAudioChanges() {
        // Headphones in or out can change the output format: reconnect, then start again.
        observers.append(Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .AVAudioEngineConfigurationChange) {
                self?.reconnectOutput()
            }
        })
        // After a call, Siri or a route change, just make sure the engine runs again.
        for name in [AVAudioSession.interruptionNotification, AVAudioSession.routeChangeNotification] {
            observers.append(Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(named: name) {
                    self?.ensureRunning()
                }
            })
        }
    }

    private func reconnectOutput() {
        engine.stop()
        let hardware = engine.outputNode.outputFormat(forBus: 0)
        if hardware.sampleRate > 0, hardware.channelCount > 0,
           let output = AVAudioFormat(standardFormatWithSampleRate: hardware.sampleRate,
                                      channels: hardware.channelCount) {
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: output)
        }
        engine.prepare()
        ensureRunning()
    }

    // MARK: Notes

    private func noteKeys() -> [NoteKey] {
        var keys: [NoteKey] = []
        for (string, fret) in chord.frets.enumerated() where fret >= 0 {
            for layer in StrumVoicing.layerVelocities.indices {
                for variant in 0..<Self.variants {
                    keys.append(NoteKey(string: string, fret: fret, layer: layer, variant: variant))
                }
            }
        }
        return keys
    }

    /// The cached note, or synthesised right now if prepare() has not finished yet.
    private func buffer(for key: NoteKey) -> AVAudioPCMBuffer? {
        if let cached = notes[key] { return cached }
        var random = SystemRandomNumberGenerator()
        let made = makeBuffer(Self.render(key, chord: chord, settings: settings,
                                          sampleRate: sampleRate, random: &random))
        notes[key] = made
        return made
    }

    nonisolated private static func render(_ key: NoteKey, chord: GuitarChord, settings: GuitarSoundSettings,
                                           sampleRate: Double, random: inout some RandomNumberGenerator) -> [Float] {
        KarplusStrong.pluck(sampleRate: sampleRate, midi: KarplusStrong.openMidi[key.string] + key.fret,
                            velocity: StrumVoicing.layerVelocities[key.layer],
                            instrument: settings.instrument, sustain: settings.sustain,
                            brightness: settings.brightness, random: &random)
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            if let base = source.baseAddress { channel.update(from: base, count: samples.count) }
        }
        return buffer
    }

    private static func audioTime(_ seconds: TimeInterval) -> AVAudioTime {
        AVAudioTime(hostTime: AVAudioTime.hostTime(forSeconds: seconds))
    }
}
