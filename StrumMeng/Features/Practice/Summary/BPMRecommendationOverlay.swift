//
//  BPMRecommendationOverlay.swift
//  StrumMeng
//
//  Created by Sharon Tan on 28/10/26.
//

import SwiftUI

/// An overlay presenting tempo recommendations following a practice session.
///
/// Designed to be overlaid cleanly on top of `PracticePlayView` (or presented from `SummaryView`),
/// using the official Retry assets (`Retry_Box`, `Retry_Character`, `Retry_Bubble`).
struct BPMRecommendationOverlay: View {
    let recommendation: RecommendedBPM
    let offTempoCount: Int
    var onKeepPrevious: () -> Void
    var onStartRecommended: (Int) -> Void

    // MARK: - Animation States
    @State private var bannerEntered: Bool = false
    @State private var mascotEntered: Bool = false
    @State private var bubbleEntered: Bool = false
    @State private var buttonsEntered: Bool = false

    init(
        recommendation: RecommendedBPM,
        offTempoCount: Int,
        onKeepPrevious: @escaping () -> Void = {},
        onStartRecommended: @escaping (Int) -> Void = { _ in }
    ) {
        self.recommendation = recommendation
        self.offTempoCount = offTempoCount
        self.onKeepPrevious = onKeepPrevious
        self.onStartRecommended = onStartRecommended
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

    // MARK: - Arcade Entrance Choreography
    private func triggerEntranceAnimation() {
        // Step 1: Retry_Box (Red comic slash banner) slashes in from right to left
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

        // Step 4: Action buttons appear and lock into place
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.36)) {
            buttonsEntered = true
        }
    }

    // MARK: - Overlay Canvas (1376 x 1032)
    @ViewBuilder
    private var overlayCanvas: some View {
        ZStack {
            // 1. Red angled comic banner in the background (Retry_Box)
            retryBanner
                .offset(x: bannerEntered ? 0 : AppLayout.referenceSize.width + 400)

            // 2. Character on the bottom left (Retry_Character)
            retryCharacter
                .offset(x: mascotEntered ? 0 : -AppLayout.referenceSize.width / 2)
                .opacity(mascotEntered ? 1.0 : 0.0)

            // 3. Speech bubble with dynamic text (Retry_Bubble)
            speechBubble
                .scaleEffect(bubbleEntered ? 1.0 : 0.1)
                .opacity(bubbleEntered ? 1.0 : 0.0)

            // 4. Action buttons below the speech bubble
            actionButtons
                .offset(y: buttonsEntered ? 0 : 25)
                .opacity(buttonsEntered ? 1.0 : 0.0)
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
    }

    // MARK: - Retry Banner (Retry_Box)
    private var retryBanner: some View {
        Image("Retry_Box")
            .resizable()
            .scaledToFit()
            .frame(width: 1572)
            .position(x: AppLayout.referenceSize.width / 2, y: AppLayout.referenceSize.height / 2)
    }

    // MARK: - Character Mascot (Retry_Character)
    private var retryCharacter: some View {
        Image("Retry_Character")
            .resizable()
            .scaledToFit()
            .frame(width: 920)
            .position(x: 450, y: 567)
    }

    // MARK: - Speech Bubble (Retry_Bubble)
    private var speechBubble: some View {
        ZStack {
            Image("Retry_Bubble")
                .resizable()
                .scaledToFit()
                .frame(width: 740)

            Text(speechText)
                .font(AppTypography.dmMono(size: 23))
                .fontWeight(.medium)
                .foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(width: 580)
                .offset(x: 35, y: -5)
        }
        .position(x: 880, y: 460)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                onStartRecommended(recommendation.targetBPM)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                    OutlinedText(
                        text: "Start With \(recommendation.targetBPM) BPM",
                        font: AppTypography.bungee(size: 38),
                        foregroundColor: AppColors.yellowAccent,
                        outlineColor: AppColors.brownInk,
                        outlineWidth: 5,
                        shadowColor: AppColors.brownPrimary,
                        shadowOffset: CGSize(width: 0, height: 0)
                    )
                }
                .foregroundStyle(AppColors.brownInk)
            }
            .buttonStyle(OverlayScaleButtonStyle())

            Button {
                onKeepPrevious()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                    Text("KEEP PREVIOUS BPM")
                        .font(AppTypography.bungee(size: 38))
                }
                .foregroundStyle(Color.white)
            }
            .buttonStyle(OverlayScaleButtonStyle())
        }
        .frame(width: 580, alignment: .leading)
        .position(x: 960, y: 670)
    }

    // MARK: - Helpers
    private var speechText: String {
        let countText = offTempoCount == 1 ? "1 time" : "\(offTempoCount) times"
        if offTempoCount > 0 {
            return "You lost the tempo \(countText) last time. Try starting at \(recommendation.targetBPM) BPM, or challenge yourself at your previous BPM?"
        } else {
            return "All on tempo! Ready to level up to \(recommendation.targetBPM) BPM, or keep practicing at your previous BPM?"
        }
    }
}

// MARK: - Button Style (Touch response without opacity fade)
private struct OverlayScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.02), value: configuration.isPressed)
    }
}

// MARK: - Previews
#Preview("Overlay Standalone", traits: .landscapeLeft) {
    BPMRecommendationOverlay(
        recommendation: RecommendedBPM(currentBPM: 70, targetBPM: 50, accuracy: 0.45, delta: -20),
        offTempoCount: 7
    )
}

#Preview("Overlay on Viewplay (Exact Mockup Match)", traits: .landscapeLeft) {
    ZStack {
        // The real PracticePlayView underneath
        PracticePlayDemoView()

        // The recommendation overlay on top
        BPMRecommendationOverlay(
            recommendation: RecommendedBPM(currentBPM: 70, targetBPM: 50, accuracy: 0.45, delta: -20),
            offTempoCount: 7
        )
    }
}
