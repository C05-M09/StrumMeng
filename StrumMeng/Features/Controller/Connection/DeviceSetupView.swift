import SwiftUI

/// iPad: shows the code to type on the iPhone and whether the iPhone is connected.
/// Laid out in `AppLayout.referenceSize` on the Listen / Play board, like the other screens.
struct DeviceSetupView: View {
    let viewModel: DeviceSetupViewModel

    var body: some View {
        GeometryReader { proxy in
            let size = AppLayout.referenceSize
            let scale = max(proxy.size.width / size.width, proxy.size.height / size.height)

            ZStack {
                Image("Play_BG").resizable()
                title
                BackButton { viewModel.send(.tapBack) }
                    .position(BackButton.referenceCenter)
                lane.position(x: size.width / 2, y: 540)
                ChunkyButton(title: "Done", fontSize: 44, width: 294, height: 96, hasDropShadow: true) {
                    viewModel.send(.tapDone)
                }
                .disabled(!viewModel.canFinish)
                .opacity(viewModel.canFinish ? 1 : 0.45)
                .position(x: 1140, y: 884)
            }
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .statusBarHidden()
        .onAppear { viewModel.appear() }
        .onDisappear { viewModel.disappear() }
    }

    private var title: some View {
        // One line and low in the banner: wide iPads crop the top of the reference space.
        OutlinedText(text: "SET UP DEVICE", font: AppTypography.bungee(size: 60),
                     foregroundColor: AppColors.white, outlineColor: AppColors.brownInk,
                     outlineWidth: 6, shadowColor: AppColors.brownInk, shadowOffset: .zero,
                     alignment: .center)
            .position(x: AppLayout.referenceSize.width / 2, y: 100)
    }

    @ViewBuilder
    private var lane: some View {
        switch viewModel.state {
        case .searching:
            VStack(spacing: AppSpacing.xl) {
                heading("Enter this code on your iPhone", color: AppColor.titleText)
                PairCodeSlotsView(code: viewModel.pairCode, slotSize: CGSize(width: 120, height: 150))
                steps
            }
        case let .connected(latencyMs):
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.xs) {
                    heading("Connected", color: AppColor.perfect, size: 92)
                    detail("iPhone is ready to strum")
                }
                detail("Device latency: \(Int(latencyMs.rounded())) ms")
            }
        case .reconnecting:
            VStack(spacing: AppSpacing.l) {
                heading("Reconnecting...", color: AppColor.tooEarly, size: 72)
                detail("Keep StrumMeng open on your iPhone")
            }
        case .failed:
            VStack(spacing: AppSpacing.l) {
                heading("Could not start", color: AppColor.miss, size: 72)
                detail("Allow Local Network in Settings, then open this again")
            }
        }
    }

    private func detail(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.dmMono(size: 34))
            .foregroundStyle(AppColor.titleText)
    }

    private func heading(_ text: String, color: Color, size: CGFloat = 44) -> some View {
        Text(text.uppercased())
            .font(AppTypography.bungee(size: size))
            .foregroundStyle(color)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            Text("1. Join the same Wi-Fi on both devices")
            Text("2. Open StrumMeng on your iPhone")
        }
        .font(AppTypography.dmMono(size: 30))
        .foregroundStyle(AppColor.titleText)
    }
}

#if DEBUG
/// Stands in for the link in previews, which only show the state they are given.
private struct PreviewControllerLink: ControllerLink {
    let pairCode = PairCode("482913") ?? .random()
    var strums: AsyncStream<StrumEvent> { AsyncStream { $0.finish() } }
    var connectionStates: AsyncStream<ControllerConnectionState> { AsyncStream { $0.finish() } }
    func start() async throws {}
    func refreshIfNeeded() async throws {}
    func setSessionActive(_ active: Bool) async {}
    func stop() async {}
}

#Preview("Searching", traits: .landscapeLeft) {
    DeviceSetupView(viewModel: DeviceSetupViewModel(link: PreviewControllerLink(), state: .searching, onClose: {}))
}

#Preview("Connected", traits: .landscapeLeft) {
    DeviceSetupView(viewModel: DeviceSetupViewModel(link: PreviewControllerLink(), state: .connected(latencyMs: 12), onClose: {}))
}

#Preview("Reconnecting", traits: .landscapeLeft) {
    DeviceSetupView(viewModel: DeviceSetupViewModel(link: PreviewControllerLink(), state: .reconnecting, onClose: {}))
}

#Preview("Failed", traits: .landscapeLeft) {
    DeviceSetupView(viewModel: DeviceSetupViewModel(link: PreviewControllerLink(), state: .failed, onClose: {}))
}
#endif
