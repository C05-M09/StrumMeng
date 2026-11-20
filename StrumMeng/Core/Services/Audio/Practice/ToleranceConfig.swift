import Foundation

/// The only place timing tolerances live. Placeholder values until tuned on a real iPad with a
/// real guitar (ARCHITECTURE.md §9).
struct ToleranceConfig: Sendable, Equatable {
    /// A strum within ± this of the (latency-corrected) beat is Perfect.
    var perfectWindowMs: Double
    /// A strum up to this long before the beat, outside the Perfect window, is Too Early.
    var earlyWindowMs: Double
    /// The whole window (early + perfect) never takes more than this fraction of one step, so the
    /// windows of neighbouring steps never overlap at high BPM.
    var maxWindowFraction: Double

    /// ±80 ms Perfect, Too Early up to 180 ms before. Players keep time slightly ahead of the beat
    /// (typically 20–50 ms early), so the earlier ±50 ms marked about a quarter of a typical player's
    /// strums Too Early. The iPhone input itself adds only a few ms (touch timestamps, clock sync).
    /// Still to be confirmed with the offsets measured on a real iPad + iPhone.
    static let standard = ToleranceConfig(perfectWindowMs: 80, earlyWindowMs: 180, maxWindowFraction: 0.9)

    /// Windows in seconds for a step interval, scaled down together when they would overlap.
    func windows(stepInterval: TimeInterval) -> (perfect: TimeInterval, early: TimeInterval) {
        let perfect = max(0, perfectWindowMs) / 1000
        let early = max(perfect, earlyWindowMs / 1000)
        let cap = stepInterval * maxWindowFraction
        guard early + perfect > cap, early + perfect > 0 else { return (perfect, early) }
        let scale = cap / (early + perfect)
        return (perfect * scale, early * scale)
    }
}
