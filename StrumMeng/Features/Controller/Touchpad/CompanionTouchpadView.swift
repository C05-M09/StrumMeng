import CoreMotion
import SwiftUI

/// iPhone strum pad: each swipe goes to the iPad and shows its direction here.
struct CompanionTouchpadView: View {
    let viewModel: CompanionViewModel

    /// How long the last strum's node stays fully visible, then how long it takes to fade out.
    /// Purely cosmetic, so a sleeping task is fine (this is not beat timing).
    private static let nodeHold: Duration = .milliseconds(600)
    private static let nodeFade: TimeInterval = 0.4

    @State private var pulse = false
    @State private var nodeOpacity: Double = 1
    @State private var motionManager = CMMotionManager()

    private var arrowRotationDegrees: Double {
        viewModel.isLeftEdgeDown ? 90 : -90
    }

    var body: some View {
        ZStack {
            // The neck runs up the screen and the sound hole sits at the bottom, so strumming crosses
            // the strings left and right. Flipped horizontally when the left edge faces the floor so
            // the thick bass strings always stay on the UP (ceiling) side and thin treble strings on
            // the DOWN (floor) side.
            Image("Companion_Guitar")
                .resizable()
                .scaledToFill()
                .scaleEffect(x: viewModel.isLeftEdgeDown ? -1 : 1)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            CompanionTouchSurface(
                onMove: { dx, touchAge in viewModel.swipe(dx: dx, touchAge: touchAge) },
                onEnd: { viewModel.endSwipe() }
            )
            .ignoresSafeArea()

            VStack {
                // The iPad-disconnected popup offers Enter Code, so Unpair would only repeat it
                // behind the veil.
                if viewModel.state != .ipadDisconnected {
                    unpairBar
                }
                Spacer()
                strumIndicator
                Spacer()
            }
            .padding(AppSpacing.m)
        }
        .onAppear(perform: startGravityTracking)
        .onDisappear(perform: stopGravityTracking)
        .onChange(of: viewModel.strumCount) {
            pulse = true
            withAnimation(.easeOut(duration: 0.2)) { pulse = false }
        }
        // Each strum shows its node again and restarts the fade; the previous wait is cancelled.
        .task(id: viewModel.strumCount) {
            guard viewModel.lastStrum != nil else { return }
            nodeOpacity = 1
            try? await Task.sleep(for: Self.nodeHold)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: Self.nodeFade)) { nodeOpacity = 0 }
        }
        // The player's eyes are on the iPad, so the phone confirms each strum by feel.
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.strumCount)
    }

    private func startGravityTracking() {
        guard !motionManager.isDeviceMotionActive else { return }
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
                guard let gx = motion?.gravity.x else { return }
                viewModel.updateGravity(x: gx)
            }
        } else if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { data, _ in
                guard let ax = data?.acceleration.x else { return }
                viewModel.updateGravity(x: ax)
            }
        }
    }

    private func stopGravityTracking() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    /// No connection status here: the iPad shows the link state, and a dropped iPad mid-session
    /// gets its own popup on this phone.
    private var unpairBar: some View {
        HStack {
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
                    .rotationEffect(.degrees(arrowRotationDegrees))
                    .opacity(nodeOpacity)
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
