import SwiftUI

/// iPhone strum pad: each swipe goes to the iPad and shows its direction here.
struct CompanionTouchpadView: View {
    let viewModel: CompanionViewModel

    @State private var pulse = false

    var body: some View {
        ZStack {
            // The neck runs up the screen and the sound hole sits at the bottom, so strumming crosses
            // the strings left and right. Filled, because iPhones differ slightly in shape.
            Image("Companion_Guitar")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)

            CompanionTouchSurface(
                onMove: { dx, touchAge in viewModel.swipe(dx: dx, touchAge: touchAge) },
                onEnd: { viewModel.endSwipe() }
            )
            .ignoresSafeArea()

            VStack {
                statusBar
                Spacer()
                strumIndicator
                Spacer()
            }
            .padding(AppSpacing.m)
        }
        .onChange(of: viewModel.strumCount) {
            pulse = true
            withAnimation(.easeOut(duration: 0.2)) { pulse = false }
        }
        // The player's eyes are on the iPad, so the phone confirms each strum by feel.
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.strumCount)
    }

    private var statusBar: some View {
        HStack {
            HStack(spacing: AppSpacing.s) {
                Circle()
                    .fill(viewModel.state == .connected ? AppColor.perfect : AppColor.tooEarly)
                    .frame(width: 12, height: 12)
                Text(viewModel.state == .connected ? "Connected" : "Reconnecting...")
                    .font(AppFont.mono(14))
                    .foregroundStyle(AppColor.ink)
            }
            .padding(.horizontal, AppSpacing.m)
            .padding(.vertical, AppSpacing.s)
            .background(AppColor.paper, in: Capsule())

            Spacer()

            ChunkyButton(title: "Unpair", style: .danger, fontSize: 14, width: 90, height: 38,
                         hasDropShadow: true) {
                viewModel.send(.disconnect)
            }
        }
    }

    @ViewBuilder
    private var strumIndicator: some View {
        VStack(spacing: AppSpacing.m) {
            if let strum = viewModel.lastStrum {
                BeatNodeView(arrow: strum == .down ? .down : .up, size: 96)
                    .scaleEffect(pulse ? 1.25 : 1)
                    .rotationEffect(.degrees(-90))
            } else {
                Text("SWIPE LEFT OR RIGHT\nTO STRUM")
                    .font(AppFont.display(20))
                    .foregroundStyle(AppColor.titleText)
                    .multilineTextAlignment(.center)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("Waiting for a swipe") {
    CompanionTouchpadView(viewModel: .preview(state: .connected))
}

#Preview("Reconnecting") {
    CompanionTouchpadView(viewModel: .preview(state: .reconnecting))
}
