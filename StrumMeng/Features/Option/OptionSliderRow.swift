import SwiftUI

/// One row of the Option card: an icon, a label and a volume slider.
struct OptionSliderRow: View {
    let symbolName: String
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: OptionCardLayout.iconToSliderSpacing) {
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: OptionCardLayout.iconSize, height: OptionCardLayout.iconSize)
                .frame(width: OptionCardLayout.iconColumnWidth)
                .foregroundStyle(AppColors.brownInk)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(AppTypography.dmMono(size: OptionCardLayout.labelFontSize))
                    .foregroundStyle(AppColors.brownInk)

                OptionVolumeSlider(title: title, value: $value)
            }
        }
    }
}

#Preview("Volume 0, 0.5 and 1") {
    VStack(alignment: .leading, spacing: AppSpacing.xl) {
        OptionSliderRow(symbolName: "speaker.wave.2.fill", title: "Music", value: .constant(0))
        OptionSliderRow(symbolName: "speaker.wave.2.fill", title: "Music", value: .constant(0.5))
        OptionSliderRow(symbolName: "speaker.wave.2.fill", title: "Music", value: .constant(1))
    }
    .padding(60)
    .background(AppColor.practiceBackground)
}
