import SwiftUI

/// A playable Practice-Play session: PracticePlayView fed by PlayViewModel every frame, with an
/// up/down swipe anywhere on the screen as the strum input (until the iPhone controller exists).
struct PracticePlaySessionView: View {
    @State private var viewModel: PlayViewModel
    @Environment(\.scenePhase) private var scenePhase
    private let startImmediately: Bool

    init(viewModel: PlayViewModel, startImmediately: Bool = false) {
        _viewModel = State(initialValue: viewModel)
        self.startImmediately = startImmediately
    }

    var body: some View {
        GeometryReader { geo in
            let pauseRect = PlayScreenLayout(size: geo.size).pauseRect
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
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.onAppear()
            if startImmediately { send(.tapReady) }
        }
        .onDisappear { Task { await viewModel.onDisappear() } }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { send(.appMovedToBackground) }
        }
    }

    private func send(_ event: PracticeEvent) {
        Task { await viewModel.send(event) }
    }
}
