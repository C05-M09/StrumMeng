import SwiftUI

/// iPhone popup when the iPad left in the middle of a session (its app went to the background, or
/// it went quiet while playing). The mirror of the iPad's ControllerDisconnectedOverlay: same card
/// and the same animated "Reconnecting" dots. It closes by itself when the iPad is back; Enter Code
/// is the way out if it never returns (it unpairs, like the pad's Unpair).
struct IPadDisconnectedOverlay: View {
    let onEnterCode: () -> Void

    /// The card is drawn for the iPad's 800 × 720 modal; on the phone it fills the width.
    private static let cardAspectRatio: CGFloat = 800 / 720
    private static let cardWidthFraction: CGFloat = 0.92

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = proxy.size.width * Self.cardWidthFraction
            ZStack {
                // Covers the strum pad too, so a swipe cannot land under the popup.
                AppColors.brownInk.opacity(0.65)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())

                ZStack {
                    Image("Option_Card")
                        .resizable()
                        .scaledToFit()
                        .accessibilityHidden(true)

                    VStack(spacing: AppSpacing.m) {
                        VStack(spacing: AppSpacing.xs) {
                            Text("IPAD DISCONNECTED")
                                .font(AppTypography.bungee(size: 24))
                            VStack(spacing: 0) {
                                reconnectingLine
                                Text("Open StrumMeng on your iPad.")
                            }
                            .font(AppTypography.dmMono(size: 14))
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Reconnecting. Open StrumMeng on your iPad.")
                        }
                        .foregroundStyle(AppColors.brownInk)
                        .multilineTextAlignment(.center)

                        ChunkyButton(title: "Enter Code", style: .secondary, fontSize: 18,
                                     width: cardWidth * 0.6, height: 48, action: onEnterCode)
                    }
                    .padding(.horizontal, AppSpacing.l)
                }
                .frame(width: cardWidth, height: cardWidth / Self.cardAspectRatio)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    /// The dots fill in one by one, as on the iPad, so the player can see it is still trying.
    private var reconnectingLine: some View {
        TimelineView(.periodic(from: .now, by: ControllerDisconnectedOverlay.dotStepInterval)) { context in
            let visible = reduceMotion
                ? ControllerDisconnectedOverlay.dotCount
                : ControllerDisconnectedOverlay.visibleDotCount(at: context.date)
            HStack(spacing: 0) {
                Text("Reconnecting")
                ForEach(0..<ControllerDisconnectedOverlay.dotCount, id: \.self) { index in
                    Text(".").opacity(index < visible ? 1 : 0)
                }
            }
        }
    }
}

#Preview("iPad disconnected") {
    ZStack {
        AppColor.laneBackground.ignoresSafeArea()
        IPadDisconnectedOverlay(onEnterCode: {})
    }
}
