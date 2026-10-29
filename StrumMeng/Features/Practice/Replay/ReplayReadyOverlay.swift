//
//  ReplayReadyOverlay.swift
//  StrumMeng
//
//  Created by Sharon Tan on 29/10/26.
//

import SwiftUI

/// An entrance overlay presented before replay playback begins.
///
/// Designed to match the arcade comic aesthetic and choreographed entrance
/// animation of `BPMRecommendationOverlay` from the Summary screen, featuring
/// the yellow `Replay_Box` banner, `Retry_Character`, speech bubble, and `NEXT ▶` button.
struct ReplayReadyOverlay: View {
    var onStart: () -> Void

    // MARK: - Animation States
    @State private var bannerEntered: Bool = false
    @State private var mascotEntered: Bool = false
    @State private var bubbleEntered: Bool = false
    @State private var buttonEntered: Bool = false

    init(onStart: @escaping () -> Void = {}) {
        self.onStart = onStart
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = max(
                proxy.size.width / AppLayout.referenceSize.width,
                proxy.size.height / AppLayout.referenceSize.height
            )

            ZStack {
                // 1. Semi-transparent dark comic dim layer
                AppColor.dim.opacity(0.82)
                    .ignoresSafeArea()

                // 2. Main overlay content scaled to reference canvas (1376 x 1032)
                overlayCanvas
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
        .onAppear {
            triggerEntranceAnimation()
        }
    }

    // MARK: - Arcade Entrance Choreography (Matching Summary BPMRecommendationOverlay)
    private func triggerEntranceAnimation() {
        // Step 1: Replay_Box (Yellow comic slash banner) slashes in from right to left
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
            bannerEntered = true
        }

        // Step 2: Retry_Character dashes in from the left
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.12)) {
            mascotEntered = true
        }

        // Step 3: Comic speech bubble pops in with comic bounce
        withAnimation(.spring(response: 0.38, dampingFraction: 0.65).delay(0.24)) {
            bubbleEntered = true
        }

        // Step 4: Action button appears and locks into place
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.36)) {
            buttonEntered = true
        }
    }

    // MARK: - Overlay Canvas (1376 x 1032)
    @ViewBuilder
    private var overlayCanvas: some View {
        ZStack {
            // 1. Yellow angled comic banner in the background (Replay_Box)
            replayBanner
                .offset(x: bannerEntered ? 0 : AppLayout.referenceSize.width + 400)

            // 2. Character on the bottom left (Retry_Character)
            characterMascot
                .offset(x: mascotEntered ? 0 : -AppLayout.referenceSize.width / 2)
                .opacity(mascotEntered ? 1.0 : 0.0)

            // 3. Speech bubble with message (Retry_Bubble)
            speechBubble
                .scaleEffect(bubbleEntered ? 1.0 : 0.1)
                .opacity(bubbleEntered ? 1.0 : 0.0)

            // 4. NEXT ▶ button positioned at the bottom right of the speech bubble
            nextButton
                .offset(y: buttonEntered ? 0 : 25)
                .opacity(buttonEntered ? 1.0 : 0.0)
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
    }

    // MARK: - Replay Banner (Replay_Box)
    private var replayBanner: some View {
        Image("Replay_Box")
            .resizable()
            .scaledToFit()
            .frame(width: 1572)
            .position(x: AppLayout.referenceSize.width / 2, y: AppLayout.referenceSize.height / 2)
    }

    // MARK: - Character Mascot (Retry_Character)
    private var characterMascot: some View {
        Image("Retry_Character")
            .resizable()
            .scaledToFit()
            .frame(width: 920)
            .position(x: 450, y: 567)
    }

    // MARK: - Speech Bubble (Retry_Bubble)
    private var speechBubble: some View {
        ZStack {
            Image("Listen_Bubble")
                .resizable()
                .scaledToFit()
                .frame(width: 740)

            Text("Time for a replay. Let’s see\nhow you played!")
                .font(AppFont.mono(30))
                .fontWeight(.medium)
                .foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .frame(width: 580)
                .offset(x: 35, y: -10)
        }
        .position(x: 850, y: 650)
    }

    // MARK: - NEXT Button
    private var nextButton: some View {
        Button(action: onStart) {
            let shape = RoundedRectangle(cornerRadius: 14)
            HStack(spacing: 8) {
                Text("NEXT")
                    .font(AppFont.display(24))
                    .foregroundStyle(AppColor.ink)
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(AppColor.ink)
            }
            .frame(width: 180, height: 54)
            .background {
                ZStack {
                    shape.fill(AppColor.ink).offset(y: 5)
                    shape.fill(AppColor.buttonPrimary)
                    shape.strokeBorder(AppColor.ink, lineWidth: 3.5)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .position(x: 1140, y: 580)
    }
}

// MARK: - Previews
#Preview("Replay Ready Overlay", traits: .landscapeLeft) {
    ZStack {
        Image("Play_BG")
            .resizable()
            .ignoresSafeArea()

        ReplayReadyOverlay {
            print("NEXT tapped!")
        }
    }
}
