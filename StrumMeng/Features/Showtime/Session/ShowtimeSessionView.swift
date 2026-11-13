import SwiftUI

struct ShowtimeSessionView: View {
    @State var viewModel: ShowtimeViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.playSoundEffect) private var playSoundEffect
    // The end transition, as in Practice: banner, garage shutting, then the summary.
    @State private var isShowingBanner = false
    @State private var isGarageClosed = false
    @State private var isSummaryReady = false
    @State private var transitionTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / ShowtimeLayout.size.width,
                            geometry.size.height / ShowtimeLayout.size.height)
            ZStack {
                AppColors.brownInk.ignoresSafeArea()
                TimelineView(.animation(minimumInterval: ShowtimeLayout.frameInterval,
                                        paused: !viewModel.isAnimating)) { _ in
                    content
                }
                .frame(width: ShowtimeLayout.size.width, height: ShowtimeLayout.size.height)
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)

                if isShowingBanner, case .finished(let result) = viewModel.state {
                    PracticeTransitionBanner(result: result)
                        .transition(.opacity)
                        .zIndex(10)
                }
                Image("Garage")
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(y: isGarageClosed ? 0 : -geometry.size.height)
                    .allowsHitTesting(isGarageClosed)
                    .zIndex(20)
            }
        }
        .ignoresSafeArea().statusBarHidden().navigationBarBackButtonHidden()
        .onAppear { viewModel.appear() }
        .onDisappear {
            resetEndTransition()
            Task { await viewModel.disappear() }
        }
        .onChange(of: viewModel.state) { _, state in
            if case .finished = state {
                if transitionTask == nil { startEndTransition() }
            } else {
                // Retry and Back leave the finished run; the next one starts its own transition.
                resetEndTransition()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { send(.pause(.background)) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .listenAudioInterrupted)) { _ in
            send(.pause(.background))
        }
    }
    @ViewBuilder private var content: some View {
        if viewModel.isListening {
            ZStack {
                ShowtimeListenView(title: viewModel.timeline.song.title, bpm: viewModel.timeline.song.bpm,
                    pattern: viewModel.previewPattern, activeStep: viewModel.previewStep,
                    canReady: viewModel.canReady, patternIndex: viewModel.selectedPatternIndex,
                    patternCount: viewModel.previewPatterns.count,
                    onSelectPattern: { send(.selectPattern($0)) },
                    onReady: { send(.ready) }, onPause: { send(.pause(.user)) })
                if viewModel.state == .intro { ShowtimeIntroView { send(.next) } }
                if case .paused(_, let reason) = viewModel.state {
                    AppColors.brownInk.opacity(ShowtimeLayout.scrimOpacity)
                    if reason == .connection {
                        ControllerDisconnectedOverlay(unit: 1, isReconnected: viewModel.isControllerConnected,
                            onResume: { send(.resume) }, onBackToMenu: { send(.back) })
                    } else {
                        PauseMenuOverlay(unit: 1, onResume: { send(.resume) },
                            onRestart: { send(.restart) }, onBackToMenu: { send(.back) })
                    }
                }
            }
        } else if case .finished = viewModel.state, isSummaryReady, let summary = viewModel.summary {
            ShowtimeSummaryView(viewModel: summary, songInfo: viewModel.songInfo)
        } else {
            PracticePlayView(model: viewModel.playFrame(), backgroundAssetName: "Showtime_Assets/Showtime_BG", titleFontScale: 0.8,
                titleLineSpacing: ShowtimeLayout.titleLineSpacing, bpmColor: AppColors.white,
                onPause: { send(.pause(.user)) }, onResume: { send(.resume) },
                onRestart: { send(.restart) }, onBackToMenu: { send(.back) })
        }
    }
    private func send(_ event: ShowtimeEvent) { Task { await viewModel.send(event) } }

    /// Same timing as Practice: the banner shows over the lane's 2 s end break and holds 3 s, the
    /// garage shuts, and 1.75 s later the summary opens it again. UI timing only, not beat timing.
    private func startEndTransition() {
        playSoundEffect(.popUp)
        withAnimation(.easeOut(duration: 0.2)) { isShowingBanner = true }
        transitionTask = Task {
            try? await Task.sleep(for: .seconds(3.0))
            guard !Task.isCancelled else { return }
            playSoundEffect(.garage)
            withAnimation(.spring(response: 0.50, dampingFraction: 0.86)) { isGarageClosed = true }
            try? await Task.sleep(for: .seconds(1.75))
            guard !Task.isCancelled else { return }
            // The summary starts behind its own closed garage and opens it.
            isShowingBanner = false
            isGarageClosed = false
            isSummaryReady = true
        }
    }

    private func resetEndTransition() {
        transitionTask?.cancel()
        transitionTask = nil
        isShowingBanner = false
        isGarageClosed = false
        isSummaryReady = false
    }
}
