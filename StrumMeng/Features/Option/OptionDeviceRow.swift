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

            Button("Set Up Device", action: onSetUp)
                .buttonStyle(
                    AssetButtonStyle(
                        normalAssetName: "Button_Set Up Device_Normal",
                        pressedAssetName: "Button_Set Up Device_Pressed",
                        size: CGSize(width: OptionCardLayout.sliderWidth, height: OptionCardLayout.deviceButtonHeight)
                    )
                )
                .accessibilityLabel("Set Up Device")
        }
    }
}

#Preview {
    OptionDeviceRow(onSetUp: {})
        .padding(AppSpacing.xl)
        .background(AppColor.paper)
}
