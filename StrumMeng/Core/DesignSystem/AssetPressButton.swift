import SwiftUI

/// A button drawn from two artworks, Normal and Pressed, with a short press animation.
///
/// Unlike a SwiftUI Button (which still fires a little outside its bounds), this one follows the
/// finger exactly: dragging out of the button shows Normal again and cancels the press; the action
/// fires only when the finger is released inside the button.
/// `isLatched` keeps the Pressed artwork showing after release, for a state the button switched on
/// (for example Pause while the game is paused).
struct AssetPressButton: View {
    let normalAsset: String
    let pressedAsset: String
    let size: CGSize
    let accessibilityLabel: String
    let isLatched: Bool
    let style: AssetPressStyle
    let action: () -> Void

    @State private var isPressed: Bool

    init(normalAsset: String, pressedAsset: String, size: CGSize, accessibilityLabel: String,
         isLatched: Bool = false, isPressed: Bool = false, style: AssetPressStyle = .standard,
         action: @escaping () -> Void) {
        self.normalAsset = normalAsset
        self.pressedAsset = pressedAsset
        self.size = size
        self.accessibilityLabel = accessibilityLabel
        self.isLatched = isLatched
        self.style = style
        self.action = action
        _isPressed = State(initialValue: isPressed)
    }

    /// Art without a pressed version passes the same asset twice. Showing that twice would cross-fade
    /// two copies, and halfway through both are half transparent, so the button flickers.
    static func hasPressedArtwork(normalAsset: String, pressedAsset: String) -> Bool {
        normalAsset != pressedAsset
    }

    var body: some View {
        let showsPressed = isPressed || isLatched
        ZStack {
            if Self.hasPressedArtwork(normalAsset: normalAsset, pressedAsset: pressedAsset) {
                Image(normalAsset)
                    .resizable()
                    .scaledToFit()
                    .opacity(showsPressed ? 0 : 1)
                Image(pressedAsset)
                    .resizable()
                    .scaledToFit()
                    .opacity(showsPressed ? 1 : 0)
            } else {
                Image(normalAsset)
                    .resizable()
                    .scaledToFit()
            }
        }
        .brightness(showsPressed ? style.brightness : 0)
        .frame(width: size.width, height: size.height)
        .scaleEffect(showsPressed ? style.scale : 1)
        .offset(y: showsPressed ? style.sink : 0)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: showsPressed)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isPressed = Self.isInside(value.location, size: size)
                }
                .onEnded { value in
                    let releasedInside = Self.isInside(value.location, size: size)
                    isPressed = false
                    if releasedInside { action() }
                }
        )
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isLatched ? .isSelected : [])
        .accessibilityAction { action() }
    }

    /// True when a point (in the button's own coordinates) is on the button.
    static func isInside(_ location: CGPoint, size: CGSize) -> Bool {
        CGRect(origin: .zero, size: size).contains(location)
    }
}

#Preview("Normal, pressed, latched") {
    HStack(spacing: AppSpacing.xl) {
        AssetPressButton(normalAsset: "Button_Pause_Normal", pressedAsset: "Button_Pause_Pressed",
                         size: CGSize(width: 88, height: 96), accessibilityLabel: "Pause") {}
        AssetPressButton(normalAsset: "Button_Pause_Normal", pressedAsset: "Button_Pause_Pressed",
                         size: CGSize(width: 88, height: 96), accessibilityLabel: "Pause", isPressed: true) {}
        AssetPressButton(normalAsset: "Button_Pause_Normal", pressedAsset: "Button_Pause_Pressed",
                         size: CGSize(width: 88, height: 96), accessibilityLabel: "Pause", isLatched: true) {}
    }
    .padding(AppSpacing.xl)
    .background(AppColor.practiceBackground)
}

#Preview("Raised key, normal and pressed") {
    HStack(spacing: AppSpacing.xl) {
        AssetPressButton(normalAsset: "Companion_Key_5", pressedAsset: "Companion_Key_5",
                         size: CGSize(width: 84, height: 89), accessibilityLabel: "5",
                         style: .raisedKey) {}
        AssetPressButton(normalAsset: "Companion_Key_5", pressedAsset: "Companion_Key_5",
                         size: CGSize(width: 84, height: 89), accessibilityLabel: "5",
                         isPressed: true, style: .raisedKey) {}
    }
    .padding(AppSpacing.xl)
    .background(AppColor.practiceBackground)
}
