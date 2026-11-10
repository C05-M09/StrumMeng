import SwiftUI

/// A playable Practice-Play session: PracticePlayView fed by PlayViewModel every frame, with an
/// up/down swipe anywhere on the screen as the strum input (until the iPhone controller exists).
struct PracticePlaySessionView: View {
    @State private var viewModel: PlayViewModel
    @Environment(\.scenePhase) private var scenePhase
    private let startImmediately: Bool
    private let onTransitionComplete: ((SessionResult) -> Void)?

    @State private var completedResult: SessionResult?
    @State private var isShowingBanner: Bool = false
    @State private var isGarageClosed: Bool = false

    init(
        viewModel: PlayViewModel,
        startImmediately: Bool = false,
        onTransitionComplete: ((SessionResult) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.startImmediately = startImmediately
        self.onTransitionComplete = onTransitionComplete
    }

    var body: some View {
        GeometryReader { geo in
            let pauseRect = PlayScreenLayout(size: geo.size).pauseRect
            ZStack {
                // PracticePlayView redraws only its moving parts each frame; positions come from the
                // clock's tick times, never from the frame timer.
                PracticePlayView(
                    isAnimating: viewModel.isAnimating,
                    liveModel: { viewModel.screenModel() },
                    onReady: { send(.tapReady) },
                    onPause: { send(.tapPause) },
                    onResume: { send(.tapResume) },
                    onRestart: { send(.tapRestart) },
                    onBackToMenu: { send(.tapBackToMenu) }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // A press on the pause button (even one dragged off to cancel) is never a strum.
                            guard !pauseRect.contains(value.startLocation) else { return }
                            viewModel.dragChanged(translation: value.translation.height, eventDate: value.time)
                        }
                        .onEnded { _ in viewModel.dragEnded() }
                )

                // 1. Outcome Transition Banner ("PURRFECT!", "GETTING THERE!", "NICE TRY")
                if isShowingBanner, let result = completedResult {
                    PracticeTransitionBanner(result: result)
                        .transition(.opacity)
                        .zIndex(10)
                }

                // 2. Garage Shutter Closing Down from Top
                Image("Garage")
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(y: isGarageClosed ? 0 : -geo.size.height)
                    .allowsHitTesting(isGarageClosed)
                    .zIndex(20)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.onAppear()
            if startImmediately { send(.tapReady) }
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .finished(let result) = newState, completedResult == nil {
                startEndSessionTransition(result: result)
            }
        }
        .onDisappear { Task { await viewModel.onDisappear() } }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { send(.appMovedToBackground) }
        }
    }

    private func startEndSessionTransition(result: SessionResult) {
        completedResult = result
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingBanner = true
        }

        Task {
            // 1. Hold the banner for 3 seconds (until confetti disappears)
            try? await Task.sleep(for: .seconds(3.0))

            // 2. Garage shutter slams down from the top
            withAnimation(.spring(response: 0.50, dampingFraction: 0.86)) {
                isGarageClosed = true
            }

            // 3. Brief pause while the closed Garage logo is visible, then switch to Summary
            try? await Task.sleep(for: .seconds(0.75))
            onTransitionComplete?(result)
        }
    }

    private func send(_ event: PracticeEvent) {
        Task { await viewModel.send(event) }
    }
}
