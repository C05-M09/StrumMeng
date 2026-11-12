import SwiftUI

struct ShowtimeSessionView: View {
    @State var viewModel: ShowtimeViewModel
    @Environment(\.scenePhase) private var scenePhase

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
            }
        }
        .ignoresSafeArea().statusBarHidden().navigationBarBackButtonHidden()
        .onAppear { viewModel.appear() }
        .onDisappear { Task { await viewModel.disappear() } }
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
        } else if case .finished(let result) = viewModel.state, !viewModel.isWrappingUp {
            ShowtimeFinishedView(title: viewModel.timeline.song.title, result: result,
                onRestart: { send(.restart) }, onBack: { send(.back) })
        } else {
            PracticePlayView(model: viewModel.playFrame(), backgroundAssetName: "Showtime_Assets/Showtime_BG", titleFontScale: 0.8,
                titleLineSpacing: ShowtimeLayout.titleLineSpacing, bpmColor: AppColors.white,
                onPause: { send(.pause(.user)) }, onResume: { send(.resume) },
                onRestart: { send(.restart) }, onBackToMenu: { send(.back) })
        }
    }
    private func send(_ event: ShowtimeEvent) { Task { await viewModel.send(event) } }
}
