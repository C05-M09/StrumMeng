import Foundation

/// Strums from swipes on the iPad's own screen, until the iPhone controller link exists.
/// There is no network in between, so the strum time is the host time of the touch event itself.
final class TouchStrumInputService: StrumInputService, TouchStrumInput {
    /// Points of travel that make one strum.
    var sensitivity: Double = 12

    private var tracker = SwipeTracker()
    private var lastTranslation: Double = 0
    private var continuations: [UUID: AsyncStream<StrumEvent>.Continuation] = [:]

    /// A new stream per subscriber; ended subscribers are dropped on the next strum.
    var strums: AsyncStream<StrumEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: StrumEvent.self)
        continuations[UUID()] = continuation
        return stream
    }

    func dragChanged(translation: Double, at time: TimeInterval) {
        let dy = translation - lastTranslation
        lastTranslation = translation
        guard let direction = tracker.feed(dy, threshold: sensitivity) else { return }
        let strum = StrumEvent(id: UUID(), direction: direction, time: time)
        for (id, continuation) in continuations {
            if case .terminated = continuation.yield(strum) { continuations[id] = nil }
        }
    }

    func dragEnded() {
        lastTranslation = 0
        tracker.reset()
    }
}
