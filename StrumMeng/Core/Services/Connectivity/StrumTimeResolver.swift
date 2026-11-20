import Foundation

/// Decides the host time of a strum on the iPad. Trusts the touch time the iPhone sent, unless it
/// is implausible for when the message actually arrived (a bad clock estimate), in which case the
/// arrival time is the safer fallback.
nonisolated enum StrumTimeResolver {
    /// A touch can be at most this long before its arrival; anything older means a bad offset.
    static let maxAge: TimeInterval = 0.5
    /// A touch claiming to be later than its arrival is allowed this much clock error.
    static let maxLead: TimeInterval = 0.01

    static func hostTime(claimed: TimeInterval?, arrivedAt arrival: TimeInterval) -> TimeInterval {
        guard let claimed, claimed > arrival - maxAge, claimed < arrival + maxLead else { return arrival }
        // A strum cannot happen after it arrived, so a small lead is clock error and is clipped.
        return min(claimed, arrival)
    }
}
