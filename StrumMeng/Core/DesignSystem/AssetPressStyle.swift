import CoreGraphics

/// How an AssetPressButton moves while it is held down.
struct AssetPressStyle: Equatable, Sendable {
    /// Size while pressed, as a fraction of the normal size.
    let scale: CGFloat
    /// How far the artwork sinks while pressed, in points.
    let sink: CGFloat
    /// Brightness change while pressed; negative darkens.
    let brightness: Double
    /// Shortest time the button shows pressed. A quick tap lifts the finger within a frame or two,
    /// which would spring the button back before the press could be seen.
    let minimumPress: Duration

    /// The shrink the iPad buttons (Pause, Back) have always had.
    static let standard = AssetPressStyle(scale: 0.94, sink: 0, brightness: 0, minimumPress: .zero)

    /// For key art with a thick bottom edge (the iPhone keypad): the key sinks into that edge and
    /// darkens, so one image is enough to show a press. Every tap shows the full click.
    static let raisedKey = AssetPressStyle(scale: 0.96, sink: 3, brightness: -0.12,
                                           minimumPress: .milliseconds(110))

    /// How much longer to show pressed after release, so the press lasts at least `minimumPress`.
    func releaseDelay(afterPressedFor elapsed: Duration) -> Duration {
        max(.zero, minimumPress - elapsed)
    }
}
