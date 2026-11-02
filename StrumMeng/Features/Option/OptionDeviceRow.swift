import SwiftUI

/// The Option card's way into the iPhone controller setup. Lines up with the slider rows.
struct OptionDeviceRow: View {
    let onSetUp: () -> Void

    var body: some View {
        HStack(spacing: OptionCardLayout.iconToSliderSpacing) {
            Image(systemName: "iphone")
                .resizable()
                .scaledToFit()
                .frame(width: OptionCardLayout.iconSize, height: OptionCardLayout.iconSize)
                .frame(width: OptionCardLayout.iconColumnWidth)
                .foregroundStyle(AppColors.brownInk)
                .accessibilityHidden(true)

            ChunkyButton(
                title: "Set Up Device",
                fontSize: OptionCardLayout.deviceButtonFontSize,
                width: OptionCardLayout.sliderWidth,
                height: OptionCardLayout.deviceButtonHeight,
                hasDropShadow: true,
                action: onSetUp
            )
        }
    }
}

#Preview {
    OptionDeviceRow(onSetUp: {})
        .padding(AppSpacing.xl)
        .background(AppColor.paper)
}
