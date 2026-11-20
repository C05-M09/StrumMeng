import Foundation

/// Raw drag input from a swipe area on screen, fed in by the Play view model.
protocol TouchStrumInput: AnyObject {
    /// - Parameters:
    ///   - translation: total vertical drag since the gesture began, in points; positive = down.
    ///   - time: when the finger was at this position, in host-clock seconds (from the touch event,
    ///     not from when the app got round to handling it).
    func dragChanged(translation: Double, at time: TimeInterval)
    func dragEnded()
}
