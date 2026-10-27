import Foundation

/// Turns continuous vertical finger movement into strums. A strum fires as soon as the finger has
/// travelled `threshold` points (not when it lifts), and the direction can reverse inside one
/// gesture (down-up-down...). Ported from the prototype.
struct SwipeTracker: Equatable {
    private var position: Double = 0
    private var anchor: Double = 0
    private var last: StrumDirection?

    mutating func reset() {
        self = SwipeTracker()
    }

    /// - Parameter dy: movement since the last call; positive = finger moving down.
    mutating func feed(_ dy: Double, threshold: Double) -> StrumDirection? {
        position += dy
        switch last {
        case nil:
            if position - anchor >= threshold { return fire(.down) }
            if anchor - position >= threshold { return fire(.up) }
        case .down:
            anchor = max(anchor, position)
            if anchor - position >= threshold { return fire(.up) }
        case .up:
            anchor = min(anchor, position)
            if position - anchor >= threshold { return fire(.down) }
        }
        return nil
    }

    private mutating func fire(_ direction: StrumDirection) -> StrumDirection {
        last = direction
        anchor = position
        return direction
    }
}
