import Foundation

/// Schedules the same C-chord GuitarSound used by Practice. One clock drives sound and highlights.
/// Continues looping for listening; emits finished only once, after the first complete pattern.
@MainActor
final class PatternStrumDemoPlayer: SongDemoPlayer {
    private let clock: any BeatClock
    private let sound: any GuitarSound
    private let now: () -> TimeInterval
    private var strokes: [Stroke] = []
    private var interval: TimeInterval = 0
    private var task: Task<Void, Never>?
    private var continuation: AsyncStream<SongDemoEvent>.Continuation?
    private var anchor: TimeInterval?
    private var frozen: TimeInterval = 0
    private var running = false
    private var completedFirstLoop = false
    private var generation = 0

    init(clock: any BeatClock, sound: any GuitarSound, now: @escaping () -> TimeInterval) {
        self.clock = clock; self.sound = sound; self.now = now
    }
    var events: AsyncStream<SongDemoEvent> {
        let channel = AsyncStream.makeStream(of: SongDemoEvent.self)
        continuation?.finish()
        continuation = channel.continuation
        return channel.stream
    }
    var elapsed: TimeInterval { max(0, anchor.map { now() - $0 } ?? frozen) }

    func start(pattern: StrumPattern, bpm: Int) async {
        let run = generation + 1
        await stop()
        guard generation == run, bpm > 0, !pattern.strokes.isEmpty else { return }
        strokes = pattern.strokes
        interval = 60 / Double(bpm) / 2
        running = true
        let ticks = clock.beatStream
        task = Task { [weak self] in
            for await tick in ticks {
                guard !Task.isCancelled, let self, self.generation == run else { return }
                self.receive(tick)
            }
        }
        await clock.start(bpm: bpm)
    }
    func pause() async {
        frozen = elapsed; anchor = nil; running = false
        sound.stopStrums()
        await clock.pause()
    }
    func resume() async {
        guard !running, !strokes.isEmpty else { return }
        running = true
        await clock.resume()
    }
    func stop() async {
        generation += 1
        task?.cancel(); task = nil
        running = false; anchor = nil; frozen = 0; completedFirstLoop = false
        sound.stopStrums()
        await clock.stop()
    }
    /// Tests inject ticks and host times here; no real-time waits or audio hardware are required.
    func receive(_ tick: BeatTick) {
        guard running, !strokes.isEmpty else { return }
        let firstAfterResume = anchor == nil
        anchor = tick.expectedTime - Double(tick.index) * interval
        // The next step is normally scheduled one tick in advance. Pause cancelled that note.
        if firstAfterResume { schedule(tick.index, at: tick.expectedTime) }
        schedule(tick.index + 1, at: tick.expectedTime + interval)
        if tick.index >= strokes.count, !completedFirstLoop {
            completedFirstLoop = true
            continuation?.yield(.finished)
        }
        continuation?.yield(.step(tick.index % strokes.count))
    }
    private func schedule(_ index: Int, at time: TimeInterval) {
        switch strokes[index % strokes.count] {
        case .down: sound.strum(.down, at: time, accent: 1)
        case .up: sound.strum(.up, at: time, accent: 0.9)
        case .rest: break
        }
    }
}
