import SwiftUI

/// iPhone strum pad. Dummy: swipes show their direction here and are not sent to the iPad yet.
/// The real pad will be a UIView using UITouch.timestamp (CLAUDE.md §2).
struct CompanionTouchpadView: View {
    let viewModel: CompanionViewModel

    @State private var lastX: CGFloat?
    @State private var pulse = false

    var body: some View {
        ZStack {
            CompanionGuitarPlaceholderView()
                .contentShape(Rectangle())
                .gesture(swipeGesture)

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
    }

    private var statusBar: some View {
        HStack {
            HStack(spacing: AppSpacing.s) {
                Circle().fill(AppColor.perfect).frame(width: 12, height: 12)
                Text("Connected")
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
            } else {
                Text("SWIPE LEFT OR RIGHT\nTO STRUM")
                    .font(AppFont.display(20))
                    .foregroundStyle(AppColor.titleText)
                    .multilineTextAlignment(.center)
            }
        }
        .allowsHitTesting(false)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if let lastX { viewModel.swipe(dx: value.location.x - lastX) }
                lastX = value.location.x
            }
            .onEnded { _ in
                lastX = nil
                viewModel.endSwipe()
            }
    }
}

#Preview("Waiting for a swipe") {
    CompanionTouchpadView(viewModel: CompanionViewModel(state: .connected))
}
