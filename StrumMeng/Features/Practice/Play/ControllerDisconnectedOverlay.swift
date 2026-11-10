import SwiftUI

/// Full-screen notice shown when the iPhone controller drops during a session. It is deliberately
/// not the pause card, so the player can tell the app stopped on its own. Resume stays disabled
/// until the iPhone is connected again; Back to Menu always works.
struct ControllerDisconnectedOverlay: View {
    let unit: CGFloat
    let isReconnected: Bool
    let onResume: () -> Void
    let onBackToMenu: () -> Void

    /// Disabled Resume is greyed and tinted rather than faded: a faded button lets the lane's
    /// nodes show through it. (`brightness` would also darken the artwork's transparent edge.)
    private static let disabledSaturation = 0.0
    private static let buttonSize = CGSize(width: 510, height: 88)

    var body: some View {
        ZStack {
            AppColors.brownInk.opacity(0.9)

            VStack(spacing: 20 * unit) {
                Text(isReconnected ? "IPHONE CONNECTED" : "IPHONE DISCONNECTED")
                    .font(AppTypography.bungee(size: 64 * unit))
                    .foregroundStyle(AppColors.cream)

                Text(isReconnected
                     ? "Your iPhone is back.\nTap Resume to continue."
                     : "Reconnecting...\nKeep StrumMeng open on your iPhone.")
                    .font(AppTypography.dmMono(size: 30 * unit))
                    .foregroundStyle(isReconnected ? AppColors.yellowAccent : AppColors.cream)
                    .padding(.bottom, 24 * unit)

                assetButton("Resume", normal: "Button_Resume_Normal", pressed: "Button_Resume_Pressed",
                            action: onResume)
                    .disabled(!isReconnected)
                    .saturation(isReconnected ? 1 : Self.disabledSaturation)
                    .colorMultiply(isReconnected ? AppColors.white : AppColors.tan)
                assetButton("Back to Menu", normal: "Button_Back to Menu_Normal",
                            pressed: "Button_Back to Menu_Pressed", action: onBackToMenu)
            }
            .multilineTextAlignment(.center)
            .animation(.easeOut(duration: 0.2), value: isReconnected)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func assetButton(_ label: String, normal: String, pressed: String,
                             action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(AssetButtonStyle(
                normalAssetName: normal, pressedAssetName: pressed,
                size: CGSize(width: Self.buttonSize.width * unit, height: Self.buttonSize.height * unit)))
            .accessibilityLabel(label)
    }
}

#Preview("Disconnected", traits: .landscapeLeft) {
    ZStack {
        Image("Play_BG").resizable().ignoresSafeArea()
        ControllerDisconnectedOverlay(unit: 1, isReconnected: false, onResume: {}, onBackToMenu: {})
            .ignoresSafeArea()
    }
}

#Preview("Reconnected", traits: .landscapeLeft) {
    ZStack {
        Image("Play_BG").resizable().ignoresSafeArea()
        ControllerDisconnectedOverlay(unit: 1, isReconnected: true, onResume: {}, onBackToMenu: {})
            .ignoresSafeArea()
    }
}
