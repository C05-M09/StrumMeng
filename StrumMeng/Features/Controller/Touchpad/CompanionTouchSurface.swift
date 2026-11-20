import SwiftUI
import UIKit

/// Horizontal finger movement with the age of each touch event. A UIView rather than a SwiftUI
/// gesture because it gives UITouch.timestamp and the coalesced touches between screen frames
/// (CLAUDE.md §2), so a strum keeps the time the finger really crossed the threshold.
struct CompanionTouchSurface: UIViewRepresentable {
    /// Movement in points since the last call (positive = right), and how long ago it happened.
    let onMove: (_ dx: Double, _ touchAge: TimeInterval) -> Void
    let onEnd: () -> Void

    func makeUIView(context: Context) -> CompanionTouchSurfaceView {
        CompanionTouchSurfaceView()
    }

    func updateUIView(_ view: CompanionTouchSurfaceView, context: Context) {
        view.onMove = onMove
        view.onEnd = onEnd
    }
}

/// Follows the newest finger, so a palm resting on the screen does not block the strumming hand.
final class CompanionTouchSurfaceView: UIView {
    var onMove: ((Double, TimeInterval) -> Void)?
    var onEnd: (() -> Void)?

    private var activeTouch: UITouch?
    private var lastX: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if activeTouch != nil { onEnd?() }
        activeTouch = touch
        lastX = touch.location(in: self).x
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch, touches.contains(activeTouch) else { return }
        let uptime = ProcessInfo.processInfo.systemUptime
        for touch in event?.coalescedTouches(for: activeTouch) ?? [activeTouch] {
            let x = touch.location(in: self).x
            onMove?(x - lastX, uptime - touch.timestamp)
            lastX = x
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    private func finish(_ touches: Set<UITouch>) {
        guard let activeTouch, touches.contains(activeTouch) else { return }
        self.activeTouch = nil
        onEnd?()
    }
}
