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
            try? await Task.sleep(for: .seconds(1.75))
            onTransitionComplete?(result)
        }
    }

    private func send(_ event: PracticeEvent) {
        Task { await viewModel.send(event) }
    }
}

#if DEBUG
private final class PreviewBeatClock: BeatClock, @unchecked Sendable {
    let beatStream: AsyncStream<BeatTick>
    private let continuation: AsyncStream<BeatTick>.Continuation
    private var tickTask: Task<Void, Never>?
    private let autoStrumContinuation: AsyncStream<StrumEvent>.Continuation?
    private let pattern: StrumPattern?

    init(pattern: StrumPattern? = nil, autoStrumContinuation: AsyncStream<StrumEvent>.Continuation? = nil) {
        var cont: AsyncStream<BeatTick>.Continuation!
        beatStream = AsyncStream { cont = $0 }
        continuation = cont
        self.pattern = pattern
        self.autoStrumContinuation = autoStrumContinuation
    }

    func start(bpm: Int) async {
        tickTask?.cancel()
        let interval = AudioBeatClock.stepInterval(bpm: bpm)
        let cont = continuation
        let strumCont = autoStrumContinuation
        let pattern = self.pattern
        tickTask = Task {
            let startTime = ProcessInfo.processInfo.systemUptime
            var index = 0
            while !Task.isCancelled {
                let expected = startTime + Double(index) * interval
                cont.yield(BeatTick(index: index, expectedTime: expected))

                if let pattern, let strumCont, index >= PlayViewModel.countInSteps {
                    let step = index - PlayViewModel.countInSteps
                    if step < pattern.strokes.count {
                        let stroke = pattern.strokes[step]
                        if stroke == .down || stroke == .up {
                            strumCont.yield(
                                StrumEvent(
                                    id: UUID(),
                                    direction: stroke == .down ? .down : .up,
                                    time: expected
                                )
                            )
                        }
                    }
                }

                index += 1
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func pause() async { tickTask?.cancel() }
    func resume() async {}
    func stop() async { tickTask?.cancel() }
}

private struct PreviewStrumInput: StrumInputService {
    let strums: AsyncStream<StrumEvent>

    init(strums: AsyncStream<StrumEvent> = AsyncStream { _ in }) {
        self.strums = strums
    }
}

private struct PreviewTransitionRepository: SessionRepository {
    func save(_ result: SessionResult) async throws {}
    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] { [] }
    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? { nil }
    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy: RecordSortCriterion
    ) async throws -> [SessionResult] { [] }
}

private struct GarageTransitionPreviewHost: View {
    @State private var runID = UUID()
    @State private var finishedResult: SessionResult?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let result = finishedResult {
                SummaryView(
                    viewModel: SummaryViewModel(
                        result: result,
                        repository: PreviewTransitionRepository()
                    ),
                    showIntroOverlay: true
                )
            } else {
                PracticePlaySessionView(
                    viewModel: makeFastPreviewViewModel(),
                    startImmediately: true,
                    onTransitionComplete: { result in
                        finishedResult = result
                    }
                )
                .id(runID)
            }

            Button("Replay Transition") {
                finishedResult = nil
                runID = UUID()
            }
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(16)
        }
    }

    private func makeFastPreviewViewModel() -> PlayViewModel {
        let pattern = PatternCatalog.all[1] // Subdivision Strum
        var strumCont: AsyncStream<StrumEvent>.Continuation!
        let strumStream = AsyncStream<StrumEvent> { strumCont = $0 }
        let clock = PreviewBeatClock(pattern: pattern, autoStrumContinuation: strumCont)
        return PlayViewModel(
            pattern: pattern,
            bpm: 800,
            clock: clock,
            input: PreviewStrumInput(strums: strumStream),
            touchInput: nil,
            requiresController: false,
            leadInSteps: 0,
            repetitions: 1,
            finishBreak: 0,
            now: { ProcessInfo.processInfo.systemUptime },
            waitUntil: { time in
                let delay = time - ProcessInfo.processInfo.systemUptime
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            }
        )
    }
}

#Preview("Garage Close & Open Transition", traits: .landscapeLeft) {
    GarageTransitionPreviewHost()
}

#Preview("PracticePlaySessionView (Ready)", traits: .landscapeLeft) {
    let pattern = PatternCatalog.all[1] // Subdivision Strum
    let vm = PlayViewModel(
        pattern: pattern,
        bpm: 80,
        clock: PreviewBeatClock(),
        input: PreviewStrumInput(),
        touchInput: nil,
        requiresController: false,
        now: { ProcessInfo.processInfo.systemUptime },
        waitUntil: { time in
            let delay = time - ProcessInfo.processInfo.systemUptime
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
        }
    )
    PracticePlaySessionView(viewModel: vm, startImmediately: false)
}

#Preview("PracticePlaySessionView (Auto Start)", traits: .landscapeLeft) {
    let pattern = PatternCatalog.all[1]
    let vm = PlayViewModel(
        pattern: pattern,
        bpm: 200,
        clock: PreviewBeatClock(),
        input: PreviewStrumInput(),
        touchInput: nil,
        requiresController: false,
        now: { ProcessInfo.processInfo.systemUptime },
        waitUntil: { time in
            let delay = time - ProcessInfo.processInfo.systemUptime
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
        }
    )
    PracticePlaySessionView(viewModel: vm, startImmediately: true)
}
#endif
