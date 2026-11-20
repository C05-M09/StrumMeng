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

                Slider(value: $value, in: VolumeConfig.range, step: VolumeConfig.step)
                    .frame(width: OptionCardLayout.sliderWidth)
                    .accessibilityLabel(title)
                    .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
            }
        }
    }
}
