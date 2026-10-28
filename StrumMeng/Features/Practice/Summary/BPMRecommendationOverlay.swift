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
/// without baking in any static game board or strum backgrounds.
struct BPMRecommendationOverlay: View {
    let recommendation: RecommendedBPM
    let offTempoCount: Int
    var onKeepPrevious: () -> Void
    var onStartRecommended: (Int) -> Void

    // MARK: - Animation States
    @State private var bannersEntered: Bool = false
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
                AppColor.dim.opacity(0.8)
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
        // Step 1: Banners smash in simultaneously (Top from right-to-left, Bottom from left-to-right)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
            bannersEntered = true
        }

        // Step 2: Capybara dashes in from the left
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
            // Capybara mascot with exam paper on the left
            capybaraMascot
                .offset(x: mascotEntered ? 0 : -140)
                .opacity(mascotEntered ? 1.0 : 0.0)

            // Angled top & bottom comic banners (Sliding in like a game intro)
            topBanner
            bottomBanner

            // Speech bubble with dynamic text
            speechBubble
                .scaleEffect(bubbleEntered ? 1.0 : 0.1)
                .opacity(bubbleEntered ? 1.0 : 0.0)

            // Action buttons below the speech bubble
            actionButtons
                .offset(y: buttonsEntered ? 0 : 25)
                .opacity(buttonsEntered ? 1.0 : 0.0)
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
    }

    // MARK: - Top Angled Banner (Masuk dari KANAN ke KIRI seperti intro game)
    private var topBanner: some View {
        ZStack {
            TopAngledBannerShape()
                .fill(AppColors.redAccent)

            TopAngledBannerLine()
                .stroke(AppColors.white, lineWidth: 8)
        }
        .offset(x: bannersEntered ? 0 : AppLayout.referenceSize.width + 400)
    }

    // MARK: - Bottom Angled Banner (Masuk dari KIRI ke KANAN seperti intro game)
    private var bottomBanner: some View {
        ZStack {
            BottomAngledBannerShape()
                .fill(AppColors.redAccent)

            BottomAngledBannerLine()
                .stroke(AppColors.white, lineWidth: 8)
        }
        .offset(x: bannersEntered ? 0 : -(AppLayout.referenceSize.width + 400))
    }

    // MARK: - Capybara Mascot
    private var capybaraMascot: some View {
        Image("Capybara")
            .resizable()
            .scaledToFit()
            .frame(width: 580)
            .position(x: 270, y: 545)
    }

    // MARK: - Speech Bubble
    private var speechBubble: some View {
        ZStack {
            Image("Text_Box")
                .resizable()
                .scaledToFit()
                .frame(width: 780)

            Text(speechText)
                .font(AppTypography.dmMono(size: 24))
                .fontWeight(.medium)
                .foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(width: 560)
                .offset(x: 24, y: -20)
        }
        .position(x: 885, y: 535)
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
                    Text("START WITH \(recommendation.targetBPM) BPM")
                        .font(AppTypography.bungee(size: 40))
                }
                .foregroundStyle(AppColors.yellowAccent)
            }
            .buttonStyle(OverlayScaleButtonStyle())
            
            Button {
                onKeepPrevious()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                    Text("KEEP PREVIOUS BPM")
                        .font(AppTypography.bungee(size: 40))
                }
                .foregroundStyle(Color.white)
            }
            .buttonStyle(OverlayScaleButtonStyle())
        }
        .frame(width: 560, alignment: .leading)
        .position(x: 870, y: 740)
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

// MARK: - Banner Shapes (Angles match reference canvas)
private struct TopAngledBannerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Generous trailing bleed on the right so no gap appears during spring overshoot
        let leftY: CGFloat = 68
        let rightY: CGFloat = 164
        let slope = (rightY - leftY) / rect.width
        let minX: CGFloat = -200
        let maxX: CGFloat = rect.width + 1200

        path.move(to: CGPoint(x: minX, y: -200))
        path.addLine(to: CGPoint(x: maxX, y: -200))
        path.addLine(to: CGPoint(x: maxX, y: leftY + slope * maxX))
        path.addLine(to: CGPoint(x: minX, y: leftY + slope * minX))
        path.closeSubpath()
        return path
    }
}

private struct TopAngledBannerLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let leftY: CGFloat = 68
        let rightY: CGFloat = 164
        let slope = (rightY - leftY) / rect.width
        let minX: CGFloat = -200
        let maxX: CGFloat = rect.width + 1200
        path.move(to: CGPoint(x: minX, y: leftY + slope * minX))
        path.addLine(to: CGPoint(x: maxX, y: leftY + slope * maxX))
        return path
    }
}

private struct BottomAngledBannerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Generous trailing bleed on the left so no gap appears during spring overshoot
        let leftY: CGFloat = 848
        let rightY: CGFloat = 944
        let slope = (rightY - leftY) / rect.width
        let minX: CGFloat = -1200
        let maxX: CGFloat = rect.width + 200

        path.move(to: CGPoint(x: minX, y: leftY + slope * minX))
        path.addLine(to: CGPoint(x: maxX, y: leftY + slope * maxX))
        path.addLine(to: CGPoint(x: maxX, y: rect.height + 200))
        path.addLine(to: CGPoint(x: minX, y: rect.height + 200))
        path.closeSubpath()
        return path
    }
}

private struct BottomAngledBannerLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let leftY: CGFloat = 848
        let rightY: CGFloat = 944
        let slope = (rightY - leftY) / rect.width
        let minX: CGFloat = -1200
        let maxX: CGFloat = rect.width + 200
        path.move(to: CGPoint(x: minX, y: leftY + slope * minX))
        path.addLine(to: CGPoint(x: maxX, y: leftY + slope * maxX))
        return path
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
