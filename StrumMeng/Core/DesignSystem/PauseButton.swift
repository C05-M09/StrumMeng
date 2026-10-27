import SwiftUI

/// Pause button from the Button_Pause_Normal / Button_Pause_Pressed artwork. Pauses only when the
/// finger is released on the button; dragging off it cancels. Stays pressed while the game is paused.
struct PauseButton: View {
    /// Width of the button; the height follows the artwork, which includes its shadow.
    var size: CGFloat = 52
    var isPaused = false
    let action: () -> Void

    /// Width / height of the artwork (88.46 x 95.85).
    private static let aspectRatio: CGFloat = 88.46 / 95.85

    var body: some View {
        AssetPressButton(normalAsset: "Button_Pause_Normal", pressedAsset: "Button_Pause_Pressed",
                         size: CGSize(width: size, height: size / Self.aspectRatio),
                         accessibilityLabel: "Pause", isLatched: isPaused, action: action)
    }
}

#Preview {
    PauseButton(size: 88) {}
        .padding(AppSpacing.xl)
        .background(AppColor.practiceBackground)
}
