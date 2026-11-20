import Foundation

/// Drops the redundant UDP copies of a strum so one swipe becomes exactly one StrumEvent.
/// A value type owned by the link's network queue, so it needs no lock.
nonisolated struct StrumDeduplicator: Sendable {
    /// Copies arrive within milliseconds of each other, so a short memory is enough.
    static let capacity = 64

    private var recent: [UUID] = []

    /// True the first time an id is seen, false for every later copy.
    mutating func isNew(_ id: UUID) -> Bool {
        guard !recent.contains(id) else { return false }
        recent.append(id)
        if recent.count > Self.capacity { recent.removeFirst() }
        return true
    }
}
