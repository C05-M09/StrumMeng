import Foundation

/// Pure judgement of one step: no clock, no audio, no state. Chords are never judged.
///
/// Each step has one window, `[beat - early, beat + perfect]`, compared with the strum time minus the
/// latency offset (the offset is applied here and nowhere else). The strums inside the window are
/// read in time order, exactly as they happen live:
/// - a strum in the wrong direction makes the step a Miss, even if a right one follows;
/// - a strum in the right direction within ±perfect of the beat makes it Perfect;
/// - a strum in the right direction earlier in the window makes it Too Early, unless a Perfect
///   one follows;
/// - no strum in the window, including a late one, is a Miss.
/// Windows never overlap (ToleranceConfig caps them), so one strum can decide only one step.
enum TimingJudge {
    /// - Parameters:
    ///   - target: the step being judged; its `index` becomes `BeatEvent.stepIndex`.
    ///   - latencyOffset: seconds from calibration. Positive = the player's strums register late
    ///     (for example Bluetooth headphones), so they are moved earlier before judging.
    ///   - stepInterval: seconds per pattern step, used to cap the windows.
    static func judge(target: BeatTarget,
                      strums: [StrumEvent],
                      latencyOffset: TimeInterval,
                      stepInterval: TimeInterval,
                      config: ToleranceConfig) -> TimingJudgement {
        let (perfect, early) = config.windows(stepInterval: stepInterval)
        var inWindow: [(strum: StrumEvent, offset: TimeInterval)] = []
        for strum in strums {
            let offset: TimeInterval = strum.time - latencyOffset - target.expectedTime
            if offset >= -early, offset <= perfect {
                inWindow.append((strum, offset))
            }
        }
        inWindow.sort { $0.offset < $1.offset }

        var tooEarly: (strum: StrumEvent, offset: TimeInterval)?
        for candidate in inWindow {
            if candidate.strum.direction != target.direction {
                return judgement(target, .miss, candidate.strum, candidate.offset)
            }
            if candidate.offset >= -perfect {
                return judgement(target, .perfect, candidate.strum, candidate.offset)
            }
            tooEarly = tooEarly ?? candidate
        }
        if let tooEarly {
            return judgement(target, .tooEarly, tooEarly.strum, tooEarly.offset)
        }
        return TimingJudgement(event: BeatEvent(stepIndex: target.index, result: .miss, offsetMs: nil),
                               strumID: nil)
    }

    /// True when this strum settles the step on its own: a wrong direction anywhere in the window
    /// (Miss) or the right direction inside the Perfect window (Perfect). The step can then be shown
    /// right away instead of waiting for its window to close.
    static func decides(_ strum: StrumEvent, for target: BeatTarget, latencyOffset: TimeInterval,
                        stepInterval: TimeInterval, config: ToleranceConfig) -> Bool {
        let (perfect, early) = config.windows(stepInterval: stepInterval)
        let offset = strum.time - latencyOffset - target.expectedTime
        guard offset >= -early, offset <= perfect else { return false }
        return strum.direction != target.direction || offset >= -perfect
    }

    /// The host time after which no strum can still change this step's result.
    static func windowEnd(of target: BeatTarget, latencyOffset: TimeInterval, stepInterval: TimeInterval,
                          config: ToleranceConfig) -> TimeInterval {
        target.expectedTime + config.windows(stepInterval: stepInterval).perfect + latencyOffset
    }

    /// The offset is kept even for a wrong-direction Miss: a strum was detected, just the wrong way.
    private static func judgement(_ target: BeatTarget, _ result: BeatResult, _ strum: StrumEvent,
                                  _ offset: TimeInterval) -> TimingJudgement {
        TimingJudgement(event: BeatEvent(stepIndex: target.index, result: result, offsetMs: offset * 1000),
                        strumID: strum.id)
    }
}
