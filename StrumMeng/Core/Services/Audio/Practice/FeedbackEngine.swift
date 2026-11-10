import Foundation

/// Real-time judging for one session (a pure value type; the view model owns it and feeds it).
///
/// Steps are added as the BeatClock reaches them, strums as the player plays. Each step becomes a
/// BeatEvent as soon as its result is final:
/// - immediately when a strum settles it (right direction in the Perfect window, or a wrong
///   direction anywhere in its window), or
/// - when its window closes (Too Early or Miss).
/// Events always come out in step order, and a strum is used for at most one step.
///
/// A strum that ends up used by no step (a swipe on a rest, or a second swipe for the same step) is
/// listed in `extraStrumIDs`; the session counts it as a Miss. Strums before the first step's window
/// (the count-in) are not extra.
struct FeedbackEngine {
    let config: ToleranceConfig
    let latencyOffset: TimeInterval
    let stepInterval: TimeInterval

    private(set) var openBeats: [BeatTarget] = []
    private var strums: [StrumEvent] = []
    /// Every strum id ever added, so a resent copy is ignored even after the original was used.
    private var seenStrumIDs: Set<UUID> = []
    /// Strums that were dropped without deciding any step, in the order they were dropped.
    private(set) var extraStrumIDs: [UUID] = []
    /// Whether any step has been added yet; strums before the first step are never extra.
    private var hasStarted = false

    init(config: ToleranceConfig, latencyOffset: TimeInterval, stepInterval: TimeInterval) {
        self.config = config
        self.latencyOffset = latencyOffset
        self.stepInterval = stepInterval
    }

    /// The next moment a window closes, if any step is still open.
    var nextDeadline: TimeInterval? { openBeats.first.map(windowEnd) }

    /// A judged step has been reached by the clock.
    mutating func addBeat(_ beat: BeatTarget) -> [BeatEvent] {
        var events = close(upTo: beat.expectedTime)
        if openBeats.isEmpty {
            // Strums before this window starts cannot match this step or any later one.
            let (_, early) = config.windows(stepInterval: stepInterval)
            let windowStart = beat.expectedTime - early + latencyOffset
            drop(countingAsExtra: hasStarted) { $0.time < windowStart }
        }
        hasStarted = true
        openBeats.append(beat)
        events += finalizeDecidedBeat()
        return events
    }

    mutating func addStrum(_ strum: StrumEvent) -> [BeatEvent] {
        guard seenStrumIDs.insert(strum.id).inserted else { return [] }
        var events = close(upTo: strum.time)
        strums.append(strum)
        events += finalizeDecidedBeat()
        return events
    }

    /// Judges every open step whose window has ended by `time`.
    mutating func close(upTo time: TimeInterval) -> [BeatEvent] {
        var events: [BeatEvent] = []
        while let beat = openBeats.first, windowEnd(beat) <= time {
            openBeats.removeFirst()
            events.append(judge(beat))
        }
        return events
    }

    /// Drops everything still open (pause, restart) and returns the steps that were not judged.
    mutating func discardOpenBeats() -> [BeatTarget] {
        let dropped = openBeats
        openBeats = []
        strums = []
        return dropped
    }

    private mutating func finalizeDecidedBeat() -> [BeatEvent] {
        // Only the oldest open step may be finalized early, so events stay in step order.
        guard let beat = openBeats.first,
              strums.contains(where: {
                  TimingJudge.decides($0, for: beat, latencyOffset: latencyOffset,
                                      stepInterval: stepInterval, config: config)
              }) else { return [] }
        openBeats.removeFirst()
        return [judge(beat)]
    }

    private mutating func judge(_ beat: BeatTarget) -> BeatEvent {
        let judgement = TimingJudge.judge(target: beat, strums: strums, latencyOffset: latencyOffset,
                                          stepInterval: stepInterval, config: config)
        if let used = judgement.strumID {
            strums.removeAll { $0.id == used }
        }
        // Windows never overlap, so a strum before this window's end cannot serve a later step.
        let end = windowEnd(beat)
        drop(countingAsExtra: true) { $0.time <= end }
        return judgement.event
    }

    /// Removes the strums matching `shouldDrop`, listing them as extra when asked.
    private mutating func drop(countingAsExtra: Bool, where shouldDrop: (StrumEvent) -> Bool) {
        if countingAsExtra {
            extraStrumIDs += strums.filter(shouldDrop).map(\.id)
        }
        strums.removeAll(where: shouldDrop)
    }

    private func windowEnd(_ beat: BeatTarget) -> TimeInterval {
        TimingJudge.windowEnd(of: beat, latencyOffset: latencyOffset, stepInterval: stepInterval,
                              config: config)
    }
}
