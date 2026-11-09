import SwiftUI

/// Temporary copy until the designer supplies a single positioning/feedback illustration.
struct FirstPlayInstructionsView: View {
    let onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    var body: some View {
        ZStack {
            AppColors.brownInk.opacity(FirstPlayInstructionsLayout.scrimOpacity)
            ZStack {
                if let artwork = FirstPlayInstructionsLayout.artworkAssetName {
                    Image(artwork).resizable().scaledToFit()
                        .frame(width: FirstPlayInstructionsLayout.panelSize.width,
                               height: FirstPlayInstructionsLayout.panelSize.height)
                        .position(FirstPlayInstructionsLayout.panelCenter)
                        .accessibilityLabel("Hold your iPhone sideways like a guitar. Green: Perfect. Yellow: Too Early. Red: Miss.")
                } else {
                    Image("Option_Card").resizable()
                        .frame(width: FirstPlayInstructionsLayout.panelSize.width,
                               height: FirstPlayInstructionsLayout.panelSize.height)
                        .position(FirstPlayInstructionsLayout.panelCenter)
                        .accessibilityHidden(true)
                    placeholder
                }
                Button("Next", action: onNext)
                    .buttonStyle(AssetButtonStyle(normalAssetName: "Button_Next_Normal",
                        pressedAssetName: "Button_Next_Pressed", size: FirstPlayInstructionsLayout.nextSize))
                    .position(FirstPlayInstructionsLayout.nextCenter)
            }
            .scaleEffect(visible || reduceMotion ? 1 : 0.96)
            .opacity(visible ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: visible)
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
        .accessibilityAddTraits(.isModal)
        .onAppear { visible = true }
    }

    private var placeholder: some View {
        VStack(spacing: FirstPlayInstructionsLayout.sectionSpacing) {
            Text("BEFORE YOU STRUM")
                .font(AppTypography.bungee(size: FirstPlayInstructionsLayout.titleSize))
            Text("Hold your iPhone sideways in front of your body, like a guitar. Swipe across the screen to strum.")
                .font(AppTypography.dmMono(size: FirstPlayInstructionsLayout.bodySize))
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: FirstPlayInstructionsLayout.rowSpacing) {
                legend("Perfect — on time", color: AppColors.perfect)
                legend("Too Early — before the beat", color: AppColors.tooEarly)
                legend("Miss — late, missed, or wrong direction", color: AppColors.miss)
            }
        }
        .foregroundStyle(AppColors.brownInk)
        .frame(width: FirstPlayInstructionsLayout.contentWidth)
        .position(FirstPlayInstructionsLayout.contentCenter)
    }

    private func legend(_ text: String, color: Color) -> some View {
        HStack(spacing: FirstPlayInstructionsLayout.rowSpacing) {
            Circle().fill(color)
                .frame(width: FirstPlayInstructionsLayout.dotSize, height: FirstPlayInstructionsLayout.dotSize)
            Text(text).font(AppTypography.dmMono(size: FirstPlayInstructionsLayout.legendSize))
        }
        .frame(height: FirstPlayInstructionsLayout.rowHeight)
    }
}

#Preview("First Play positioning and feedback", traits: .landscapeLeft) {
    Image("Play_BG").resizable().overlay { FirstPlayInstructionsView(onNext: {}) }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
}
