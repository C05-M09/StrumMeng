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
    var onBack: () -> Void
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
        onBack: @escaping () -> Void = {},
        onKeepPrevious: @escaping () -> Void = {},
        onStartRecommended: @escaping (Int) -> Void = { _ in }
    ) {
        self.recommendation = recommendation
        self.offTempoCount = offTempoCount
        self.onBack = onBack
        self.onKeepPrevious = onKeepPrevious
        self.onStartRecommended = onStartRecommended
    }

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / AppLayout.referenceSize.width
            let sy = proxy.size.height / AppLayout.referenceSize.height

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
                    .scaleEffect(x: sx, y: sy)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
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

            // 5. Back button to return to summary
            BackButton(action: onBack)
                .position(BackButton.referenceCenter)
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
                .frame(width: 560)
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

            if recommendation.targetBPM != recommendation.currentBPM {
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
        }
        .frame(width: 580, alignment: .leading)
        .position(x: 960, y: 670)
    }

    // MARK: - Helpers
    private var speechText: String {
        let countText = offTempoCount == 1 ? "1 time" : "\(offTempoCount) times"
        let currentBPM = recommendation.currentBPM
        let targetBPM = recommendation.targetBPM
        let delta = recommendation.delta

        if targetBPM > currentBPM {
            if offTempoCount == 0 {
                return "All on tempo! Ready to level up to \(targetBPM) BPM, or retry at \(currentBPM) BPM?"
            } else {
                return "Sharp run! Just \(countText) off tempo. Push up to \(targetBPM) BPM, or stay at \(currentBPM) BPM?"
            }
        } else if targetBPM < currentBPM {
            if delta == -10 {
                return "Off tempo \(countText) last time. Ease back to \(targetBPM) BPM, or retry at \(currentBPM) BPM?"
            } else {
                return "You lost the beat \(countText). Slow down to \(targetBPM) BPM to nail it, or keep \(currentBPM) BPM?"
            }
        } else if delta > 0 {
            if offTempoCount == 0 {
                return "You aced max speed at \(currentBPM) BPM! Ready to run it back at \(currentBPM) BPM?"
            } else {
                return "Great run at max \(currentBPM) BPM! Just \(countText) off tempo. Retry \(currentBPM) BPM for 100%?"
            }
        } else if delta < 0 {
            return "Off tempo \(countText) at \(currentBPM) BPM. Take it steady and give \(currentBPM) BPM another shot!"
        } else if offTempoCount > 0 {
            return "Nice pace! You slipped \(countText). Let's lock in \(currentBPM) BPM before speeding up!"
        } else {
            return "Solid rhythm! Let's lock in \(currentBPM) BPM once more before speeding up!"
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
#if DEBUG
private struct BPMOverlayScenario: Identifiable {
    let id: String
    let label: String
    let recommendation: RecommendedBPM
    let offTempoCount: Int

    static let all: [BPMOverlayScenario] = [
        BPMOverlayScenario(
            id: "up-clean",
            label: "Speed Up (+10, 0 slip)",
            recommendation: RecommendedBPM(currentBPM: 80, targetBPM: 90, accuracy: 1.0, delta: 10),
            offTempoCount: 0
        ),
        BPMOverlayScenario(
            id: "up-slip",
            label: "Speed Up (+10, minor slip)",
            recommendation: RecommendedBPM(currentBPM: 80, targetBPM: 90, accuracy: 0.90, delta: 10),
            offTempoCount: 1
        ),
        BPMOverlayScenario(
            id: "max-clean",
            label: "Max 120 BPM (0 slip)",
            recommendation: RecommendedBPM(currentBPM: 120, targetBPM: 120, accuracy: 1.0, delta: 10),
            offTempoCount: 0
        ),
        BPMOverlayScenario(
            id: "max-slip",
            label: "Max 120 BPM (minor slip)",
            recommendation: RecommendedBPM(currentBPM: 120, targetBPM: 120, accuracy: 0.90, delta: 10),
            offTempoCount: 2
        ),
        BPMOverlayScenario(
            id: "stay-slip",
            label: "Stay Same (66-85%)",
            recommendation: RecommendedBPM(currentBPM: 80, targetBPM: 80, accuracy: 0.75, delta: 0),
            offTempoCount: 4
        ),
        BPMOverlayScenario(
            id: "stay-clean",
            label: "Stay Same (0 slip)",
            recommendation: RecommendedBPM(currentBPM: 80, targetBPM: 80, accuracy: 0.85, delta: 0),
            offTempoCount: 0
        ),
        BPMOverlayScenario(
            id: "down-10",
            label: "Slow Down (-10 BPM)",
            recommendation: RecommendedBPM(currentBPM: 90, targetBPM: 80, accuracy: 0.58, delta: -10),
            offTempoCount: 6
        ),
        BPMOverlayScenario(
            id: "down-20",
            label: "Slow Down (-20 BPM)",
            recommendation: RecommendedBPM(currentBPM: 90, targetBPM: 70, accuracy: 0.42, delta: -20),
            offTempoCount: 9
        ),
        BPMOverlayScenario(
            id: "min-60",
            label: "Min 60 BPM (clamped)",
            recommendation: RecommendedBPM(currentBPM: 60, targetBPM: 60, accuracy: 0.40, delta: -20),
            offTempoCount: 9
        )
    ]
}

private struct BPMOverlayScenarioBrowserPreview: View {
    @State private var index: Int = 0

    private var scenario: BPMOverlayScenario {
        BPMOverlayScenario.all[index]
    }

    var body: some View {
        ZStack(alignment: .top) {
            PracticePlayDemoView()

            BPMRecommendationOverlay(
                recommendation: scenario.recommendation,
                offTempoCount: scenario.offTempoCount
            )
            .id(scenario.id)

            HStack(spacing: 10) {
                Button("◀") {
                    index = (index - 1 + BPMOverlayScenario.all.count) % BPMOverlayScenario.all.count
                }
                .buttonStyle(.borderedProminent)

                Text("\(index + 1)/\(BPMOverlayScenario.all.count): \(scenario.label)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Button("▶") {
                    index = (index + 1) % BPMOverlayScenario.all.count
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 14)
        }
    }
}

#Preview("All BPM Scenarios", traits: .landscapeLeft) {
    BPMOverlayScenarioBrowserPreview()
}

#Preview("Overlay Standalone", traits: .landscapeLeft) {
    BPMRecommendationOverlay(
        recommendation: RecommendedBPM(currentBPM: 80, targetBPM: 60, accuracy: 0.45, delta: -20),
        offTempoCount: 7
    )
}

// PracticePlayDemoView exists in DEBUG builds only.
#Preview("Overlay on Viewplay (Exact Mockup Match)", traits: .landscapeLeft) {
    ZStack {
        // The real PracticePlayView underneath
        PracticePlayDemoView()

        // The recommendation overlay on top
        BPMRecommendationOverlay(
            recommendation: RecommendedBPM(currentBPM: 80, targetBPM: 60, accuracy: 0.45, delta: -20),
            offTempoCount: 7
        )
    }
}
#endif
