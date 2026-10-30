import Foundation

/// Plays the Listen example on the synthesised guitar, looping the pattern. Strums are scheduled a
/// little ahead on the host clock (sample-accurate); the loop only wakes up to schedule the next
/// ones, so a late wake-up never makes a strum late.
@MainActor
final class SynthListenPlayer: ListenPatternPlayer {
    /// The first strum starts this long after start or resume, so it is never cut short.
    static let startLead: TimeInterval = 0.15
    /// How far ahead strums are handed to the audio engine.
    static let lookahead: TimeInterval = 0.12
    private static let pollInterval: Duration = .milliseconds(25)

    private let sound: any GuitarSound
    private let now: () -> TimeInterval
    private var strokes: [Stroke] = []
    private var stepInterval: TimeInterval = 0
    /// Host time of step 0 of the current run.
    private var startTime: TimeInterval?
    private var pausedElapsed: TimeInterval = 0
    private var nextStep = 0
    private var loop: Task<Void, Never>?

    init(sound: any GuitarSound, now: @escaping () -> TimeInterval = HostClock.now) {
        self.sound = sound
        self.now = now
    }

    /// Time since the first strum, frozen while paused; 0 before it sounds.
    var elapsed: TimeInterval {
        guard let startTime else { return pausedElapsed }
        return max(0, now() - startTime)
    }

    func start(pattern: StrumPattern, bpm: Int) throws {
        stop()
        guard bpm > 0, !pattern.strokes.isEmpty else { throw ListenPlaybackError.invalidPattern }
        strokes = pattern.strokes
        // One stroke per eighth note in 4/4, as in Play.
        stepInterval = 60 / Double(bpm) / 2
        run(fromStep: 0, elapsed: 0)
    }

    func pause() {
        guard startTime != nil else { return }
        pausedElapsed = elapsed
        halt()
    }

    func resume() {
        guard startTime == nil, !strokes.isEmpty else { return }
        // Carry on from the first step not played yet.
        let step = Int((pausedElapsed / stepInterval).rounded(.up))
        run(fromStep: step, elapsed: pausedElapsed)
    }

    func stop() {
        halt()
        pausedElapsed = 0
        nextStep = 0
    }

    /// Hands every strum due within the lookahead to the engine. Internal so tests can drive it
    /// with a fake clock.
    func scheduleDue() {
        guard let startTime, !strokes.isEmpty else { return }
        while true {
            let time = startTime + Double(nextStep) * stepInterval
            guard time < now() + Self.lookahead else { return }
            switch strokes[nextStep % strokes.count] {
            case .down: sound.strum(.down, at: time, accent: 1)
            case .up: sound.strum(.up, at: time, accent: 0.9)
            case .rest: break
            }
            nextStep += 1
        }
    }

    private func run(fromStep step: Int, elapsed: TimeInterval) {
        nextStep = step
        // The timeline continues from `elapsed`, startLead from now, so the next strum is never cut short.
        startTime = now() + Self.startLead - elapsed
        scheduleDue()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.pollInterval)
                self?.scheduleDue()
            }
        }
    }

    private func halt() {
        loop?.cancel()
        loop = nil
        startTime = nil
        sound.stopStrums()
    }

    private enum ListenPlaybackError: Error {
        case invalidPattern
    }
}
