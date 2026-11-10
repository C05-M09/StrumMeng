import CoreGraphics

/// How an AssetPressButton moves while it is held down.
struct AssetPressStyle: Equatable, Sendable {
    /// Size while pressed, as a fraction of the normal size.
    let scale: CGFloat
    /// How far the artwork sinks while pressed, in points.
    let sink: CGFloat
    /// Brightness change while pressed; negative darkens.
    let brightness: Double

    /// The shrink the iPad buttons (Pause, Back) have always had.
    static let standard = AssetPressStyle(scale: 0.94, sink: 0, brightness: 0)

    /// For key art with a thick bottom edge (the iPhone keypad): the key sinks into that edge and
    /// darkens, so one image is enough to show a press.
    static let raisedKey = AssetPressStyle(scale: 0.96, sink: 3, brightness: -0.12)
}
