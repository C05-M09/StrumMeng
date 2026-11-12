import SwiftUI

/// Pause modal: Option_Card asset asking whether to end the session, with Resume / Restart / Back to Menu.
struct PauseMenuOverlay: View {
    let unit: CGFloat
    let onResume: () -> Void
    let onRestart: () -> Void
    let onBackToMenu: () -> Void

    var body: some View {
        ZStack {
            Image("Option_Card")
                .resizable()
                .scaledToFit()
                .frame(width: 800 * unit, height: 720 * unit)

            VStack(spacing: 20 * unit) {
                Text("ARE YOU SURE YOU WANT\nTO END THE SESSION?")
                    .font(AppTypography.bungee(size: 45 * unit))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.brownInk)
                    .padding(.bottom, 12 * unit)

                assetButton("Resume", normal: "Button_Resume_Normal", pressed: "Button_Resume_Pressed",
                            size: CGSize(width: 510 * unit, height: 88 * unit), action: onResume)
                assetButton("Restart", normal: "Button_Restart_Normal", pressed: "Button_Restart_Pressed",
                            size: CGSize(width: 510 * unit, height: 88 * unit), action: onRestart)
                assetButton("Back to Menu", normal: "Button_Back to Menu_Normal", pressed: "Button_Back to Menu_Pressed",
                            size: CGSize(width: 510 * unit, height: 88 * unit), action: onBackToMenu)
            }
        }
    }

    private func assetButton(_ label: String, normal: String, pressed: String, size: CGSize,
                             action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(AssetButtonStyle(
                normalAssetName: normal, pressedAssetName: pressed, size: size))
            .accessibilityLabel(label)
    }
}

#Preview {
    PauseMenuOverlay(unit: 1, onResume: {}, onRestart: {}, onBackToMenu: {})
        .padding(60)
        .background(AppColors.brownInk.opacity(0.65))
}
