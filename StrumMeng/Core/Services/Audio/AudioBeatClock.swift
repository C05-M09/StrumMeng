import Foundation

/// BeatClock on the host/audio clock (mach_absolute_time, the timeline AVAudioEngine uses).
/// Never Timer or asyncAfter: each tick time is `anchor + n * interval`, computed from one anchor
/// instead of adding intervals up, so there is no accumulated drift. The loop only wakes up often
/// to look at the clock and delivers each tick once its expectedTime has passed.
///
/// One tick per pattern step (an eighth note in 4/4). Sound (metronome, pattern example) is not
/// scheduled yet; when it is, it hangs off the same anchor.
final class AudioBeatClock: BeatClock {
    private let now: () -> TimeInterval
    private let startDelay: TimeInterval
    private let pollInterval: Duration

    private var interval: TimeInterval = 0.375
    private var anchorTime: TimeInterval = 0
    private var anchorIndex = 0
    private var nextIndex = 0
    private var loop: Task<Void, Never>?
    private var continuations: [UUID: AsyncStream<BeatTick>.Continuation] = [:]

    init(now: @escaping () -> TimeInterval = HostClock.now,
         startDelay: TimeInterval = 0.3,
         pollInterval: Duration = .milliseconds(4)) {
        self.now = now
        self.startDelay = startDelay
        self.pollInterval = pollInterval
    }

    /// A new stream per subscriber, so one screen ending its loop does not end the clock for the next.
    var beatStream: AsyncStream<BeatTick> {
        let (stream, continuation) = AsyncStream.makeStream(of: BeatTick.self)
        continuations[UUID()] = continuation
        return stream
    }

    func start(bpm: Int) async {
        stopLoop()
        interval = Self.stepInterval(bpm: bpm)
        run(from: 0)
    }

    func pause() async {
        stopLoop()
    }

    /// Continues with the first tick not delivered yet, `startDelay` from now.
    func resume() async {
        guard loop == nil else { return }
        run(from: nextIndex)
    }

    func stop() async {
        stopLoop()
        nextIndex = 0
    }

    /// Seconds per pattern step: two steps per beat (eighth notes in 4/4).
    static func stepInterval(bpm: Int) -> TimeInterval {
        60.0 / Double(max(1, bpm)) / 2
    }

    /// Delivers every tick that is due at `time`. Internal so the drift-free maths can be tested
    /// without waiting on real time.
    func deliverTicks(upTo time: TimeInterval) {
        while expectedTime(of: nextIndex) <= time {
            let tick = BeatTick(index: nextIndex, expectedTime: expectedTime(of: nextIndex))
            for (id, continuation) in continuations {
                if case .terminated = continuation.yield(tick) { continuations[id] = nil }
            }
            nextIndex += 1
        }
    }

    func expectedTime(of index: Int) -> TimeInterval {
        anchorTime + Double(index - anchorIndex) * interval
    }

    private func run(from index: Int) {
        anchorIndex = index
        anchorTime = now() + startDelay
        nextIndex = index
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.deliverTicks(upTo: self.now())
                try? await Task.sleep(for: self.pollInterval)
            }
        }
    }

    private func stopLoop() {
        loop?.cancel()
        loop = nil
    }
}
