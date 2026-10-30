import Foundation

/// One string of a strum: which string and fret, how hard, and how long after the strum starts.
nonisolated struct StrumNote: Sendable, Equatable {
    /// 0 = low E ... 5 = high e.
    let string: Int
    let fret: Int
    /// 0.12...1.
    let velocity: Double
    let offset: TimeInterval
}
