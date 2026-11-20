import SwiftUI

/// iPhone overlay when the iPad left in the middle of a session (its app went to the background,
/// or it went quiet while playing): white text and Enter Code straight on a dark veil, no card. The
/// "Reconnecting" dots animate like the iPad's ControllerDisconnectedOverlay. It closes by itself
/// when the iPad is back; Enter Code is the way out if it never returns (it unpairs, like Unpair).
struct IPadDisconnectedOverlay: View {
    let onEnterCode: () -> Void

    /// Dark enough for white text to keep 4.5:1 over the bright guitar artwork.
    private static let veilOpacity = 0.85
    private static let buttonWidthFraction: CGFloat = 0.6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Covers the strum pad too, so a swipe cannot land under the overlay.
                AppColors.brownInk.opacity(Self.veilOpacity)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())

                VStack(spacing: AppSpacing.l) {
                    VStack(spacing: AppSpacing.s) {
                        Text("IPAD DISCONNECTED")
                            .font(AppTypography.bungee(size: 28))
                        VStack(spacing: AppSpacing.xs) {
                            reconnectingLine
                            Text("Open StrumMeng on your iPad.")
                        }
                        .font(AppTypography.dmMono(size: 16))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Reconnecting. Open StrumMeng on your iPad.")
                    }
                    .foregroundStyle(AppColors.white)
                    .multilineTextAlignment(.center)

                    ChunkyButton(title: "Enter Code", style: .secondary, fontSize: 18,
                                 width: proxy.size.width * Self.buttonWidthFraction, height: 48,
                                 action: onEnterCode)
                }
                .padding(.horizontal, AppSpacing.l)
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
