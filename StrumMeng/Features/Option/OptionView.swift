import SwiftUI

/// The Option screen: the card with the two volume sliders and a Back button.
/// Laid out in `AppLayout.referenceSize` and scaled to the device, like `PatternListView`.
struct OptionView: View {
    let viewModel: OptionViewModel

    var body: some View {
        GeometryReader { proxy in
            let scale = max(
                proxy.size.width / AppLayout.referenceSize.width,
                proxy.size.height / AppLayout.referenceSize.height
            )

            ZStack {
                // Placeholder until the Option background artwork is in the assets.
                AppColors.brownPrimary
                    .ignoresSafeArea()
                    .opacity(0.8)

                content
                    .frame(
                        width: AppLayout.referenceSize.width,
                        height: AppLayout.referenceSize.height
                    )
                    .scaleEffect(scale)
                    .frame(
                        width: AppLayout.referenceSize.width * scale,
                        height: AppLayout.referenceSize.height * scale
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var content: some View {
        ZStack {
            OptionCardView(soundVolume: soundVolume, sfxVolume: sfxVolume)
                .position(
                    x: AppLayout.referenceSize.width / 2,
                    y: AppLayout.referenceSize.height / 2
                )
            Button {
                viewModel.send(.tapBack)
            } label: {
                Color.clear
            }
            .buttonStyle(
                AssetButtonStyle(
                    normalAssetName: "Button_Back_Normal",
                    pressedAssetName: "Button_Back_Pressed",
                    size: CGSize(width: 88.46, height: 95.85)
                )
            )
            .position(x: 109, y: 103)
            .accessibilityLabel("Back")
        }
        .frame(
            width: AppLayout.referenceSize.width,
            height: AppLayout.referenceSize.height
        )
        .clipped()
    }

    private var soundVolume: Binding<Double> {
        Binding(
            get: { viewModel.state.soundVolume },
            set: { viewModel.send(.changeSoundVolume($0)) }
        )
    }

    private var sfxVolume: Binding<Double> {
        Binding(
            get: { viewModel.state.sfxVolume },
            set: { viewModel.send(.changeSFXVolume($0)) }
        )
    }
}

#Preview {
    OptionView(
        viewModel: OptionViewModel(
            settings: UserDefaultsSettingsStore(
                defaults: UserDefaults(suiteName: "preview.option") ?? .standard
            ),
            onBackRequested: {}
        )
    )
}
