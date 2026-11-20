import Foundation

/// When the practice wheel ticks: once for every pattern it passes, like a ratchet, so a fast
/// spin sounds like a fast run of clicks and a one-step move a single click.
enum PatternWheelTicks {
    /// The pattern under the pointer while the wheel is turned by `dragAngle` from `selectedIndex`.
    /// Same direction as the wheel's rotation (turning by -angleBetween moves to the next pattern).
    static func slot(selectedIndex: Int, dragAngle: Double, angleBetween: Double, count: Int) -> Int {
        guard count > 0, angleBetween > 0 else { return 0 }
        let position = Double(selectedIndex) - dragAngle / angleBetween
        return Int(min(max(position, 0), Double(count - 1)).rounded())
    }

    /// Seconds from now of each tick while the wheel settles from pattern `from` to pattern `to`:
    /// one per pattern passed, evenly spread over the settle animation, the first one at once.
    static func settleDelays(from: Int, to: Int, duration: Double) -> [Double] {
        let steps = abs(to - from)
        guard steps > 0 else { return [] }
        let gap = max(duration, 0) / Double(steps)
        return (0..<steps).map { Double($0) * gap }
    }
}
