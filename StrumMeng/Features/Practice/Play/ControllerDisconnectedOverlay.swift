import SwiftUI

/// Modal shown when the iPhone controller drops during a session. It uses the same Option_Card as
/// the pause modal, so it feels like part of the same family, but its title says why the session
/// stopped. Resume stays disabled until the iPhone is connected again; Back to Menu always works.
struct ControllerDisconnectedOverlay: View {
    let unit: CGFloat
    let isReconnected: Bool
    let onResume: () -> Void
    let onBackToMenu: () -> Void

    /// Disabled Resume is greyed and tinted rather than faded: a faded button lets what is behind
    /// it show through. (`brightness` would also darken the artwork's transparent edge.)
    private static let disabledSaturation = 0.0
    private static let buttonSize = CGSize(width: 510, height: 88)
    private static let titleToMessageSpacing: CGFloat = 0
    static let dotCount = 3
    /// How long each step of the "Reconnecting..." dots shows. Purely cosmetic, so a periodic
    /// timeline is fine here (this is not beat timing).
    static let dotStepInterval: TimeInterval = 0.4

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How many dots after "Reconnecting" are visible at `date`: 0, 1, 2, 3, then round again.
    static func visibleDotCount(at date: Date) -> Int {
        let step = Int((date.timeIntervalSinceReferenceDate / dotStepInterval).rounded(.down))
        return step % (dotCount + 1)
    }

    /// "Reconnecting" with dots that fill in one by one, so the player can see the app is still
    /// trying. Hidden dots keep their space, so the line does not shift as they appear.
    private var reconnectingLine: some View {
        TimelineView(.periodic(from: .now, by: Self.dotStepInterval)) { context in
            let visible = reduceMotion ? Self.dotCount : Self.visibleDotCount(at: context.date)
            HStack(spacing: 0) {
                Text("Reconnecting")
                ForEach(0..<Self.dotCount, id: \.self) { index in
                    Text(".").opacity(index < visible ? 1 : 0)
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Image("Option_Card")
                .resizable()
                .scaledToFit()
                .frame(width: 800 * unit, height: 720 * unit)

            VStack(spacing: 20 * unit) {
                // Title and message sit close together as one block; the outer spacing only
                // separates that block from the buttons.
                VStack(spacing: Self.titleToMessageSpacing * unit) {
                    Text(isReconnected ? "IPHONE CONNECTED" : "IPHONE DISCONNECTED")
                        .font(AppTypography.bungee(size: 50 * unit))

                    Group {
                        if isReconnected {
                            Text("Your iPhone is back.\nTap Resume to continue.")
                        } else {
                            VStack(spacing: 0) {
                                reconnectingLine
                                Text("Keep StrumMeng open on your iPhone.")
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Reconnecting. Keep StrumMeng open on your iPhone.")
                        }
                    }
                    .font(AppTypography.dmMono(size: 24 * unit))
                }
                .foregroundStyle(AppColors.brownInk)
                .padding(.bottom, 12 * unit)

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

// The modal on its own is in PauseMenuOverlay's style; these show it where the player sees it, on
// the Play screen while the session is paused because the iPhone dropped.
#if DEBUG
#Preview("Paused - reconnecting", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 5,
                                                       disconnected: .disconnected(isReconnected: false)))
}

#Preview("Paused - iPhone back", traits: .landscapeLeft) {
    PracticePlayView(model: PracticePlayDemoView.model(songTime: 5,
                                                       disconnected: .disconnected(isReconnected: true)))
}
#endif
