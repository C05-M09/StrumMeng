//
//  HomeView.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//

import SwiftUI

/// The Home screen: the cover with the Practice, Showtime and Option buttons and the Guidebook icon.
/// Option and Guidebook open as overlays on top of Home.
/// Laid out in `AppLayout.referenceSize` and scaled to the device, like the other screens.
struct HomeView: View {
    let viewModel: HomeViewModel
    let optionViewModel: OptionViewModel
    let guidebookViewModel: GuidebookViewModel

    var body: some View {
        GeometryReader { proxy in
            let scale = max(
                proxy.size.width / AppLayout.referenceSize.width,
                proxy.size.height / AppLayout.referenceSize.height
            )

            ZStack {
                FrameAnimationView(
                    framePrefix: HomeLayout.coverAnimationPrefix,
                    frameCount: HomeLayout.coverAnimationFrameCount,
                    framesPerSecond: HomeLayout.coverAnimationFPS
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

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
        .overlay { presentedOverlayView }
        .onAppear {
            if viewModel.presentedOverlay == nil { viewModel.guidance?.send(.homeAppeared) }
        }
        .onChange(of: viewModel.presentedOverlay) { _, overlay in
            if overlay == nil { viewModel.guidance?.send(.homeAppeared) }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.presentedOverlay)
    }

    // MARK: - Content

    private var content: some View {
        ZStack {
            menuButton(HomeLayout.practice, "Practice") {
                viewModel.send(.tapPractice)
            }

            menuButton(HomeLayout.showtime, "Showtime", hint: "Not available yet") {
                viewModel.send(.tapShowtime)
            }
            // Showtime has no action yet, so it does not click either.
            .environment(\.playSoundEffect, .silent)

            menuButton(HomeLayout.option, "Option") {
                viewModel.send(.tapOption)
            }

            HomeMenuButton(
                assetName: HomeLayout.guidebookAsset,
                pressedAssetName: HomeLayout.guidebookPressedAsset,
                title: "Guidebook",
                height: HomeLayout.guidebookSize.height
            ) {
                viewModel.send(.tapGuidebook)
            }
            .position(HomeLayout.guidebookCenter)
        }
        .frame(
            width: AppLayout.referenceSize.width,
            height: AppLayout.referenceSize.height
        )
        .overlay {
            if let guidance = viewModel.guidance, guidance.state.isShowing {
                HomeGuidanceView(state: guidance.state) { guidance.send(.advance) }
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: viewModel.guidance?.state.isShowing)
        .clipped()
    }

    private func menuButton(
        _ layout: HomeLayout.MenuButton,
        _ title: String,
        hint: String = "",
        action: @escaping () -> Void
    ) -> some View {
        HomeMenuButton(
            assetName: layout.asset,
            title: title,
            height: layout.height,
            hint: hint,
            action: action
        )
        .position(layout.center)
    }

    // MARK: - Overlay (Option / Guidebook)

    @ViewBuilder
    private var presentedOverlayView: some View {
        if let presented = viewModel.presentedOverlay {
            ZStack {
                // Brown scrim at 80%: blocks taps on the Home buttons behind it
                // and closes the overlay when tapped.
//                Color("BrownPrimary")
//                    .opacity(0.1)
//                    .ignoresSafeArea()
//                    .contentShape(Rectangle())
//                    .onTapGesture { viewModel.send(.dismissOverlay) }
//                    .accessibilityLabel("Close")
//                    .accessibilityAddTraits(.isButton)

                switch presented {
                case .option:
                    OptionView(viewModel: optionViewModel)
                case .guidebook:
                    GuidebookView(viewModel: guidebookViewModel)
                }
            }
            .transition(.opacity)
            .accessibilityAddTraits(.isModal)
        }
    }
}

#Preview {
    let home = HomeViewModel(onPracticeRequested: {})
    let option = OptionViewModel(
        settings: UserDefaultsSettingsStore(),
        sounds: AVMenuSoundService(),
        onBackRequested: { [weak home] in home?.send(.dismissOverlay) }
    )
    let guidebook = GuidebookViewModel(
        onBackRequested: { [weak home] in home?.send(.dismissOverlay) }
    )
    return HomeView(
        viewModel: home,
        optionViewModel: option,
        guidebookViewModel: guidebook
    )
}
