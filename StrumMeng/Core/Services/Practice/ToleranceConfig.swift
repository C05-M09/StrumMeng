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

    static let standard = ToleranceConfig(perfectWindowMs: 50, earlyWindowMs: 150, maxWindowFraction: 0.9)

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
