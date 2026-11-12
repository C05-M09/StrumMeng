import Foundation
import Observation

@MainActor
@Observable
final class ShowtimeViewModel {
    let timeline: SongTimeline
    let previewPatterns: [StrumPattern]
    private(set) var selectedPatternIndex = 0
    private(set) var previewStep = 0
    private(set) var completedPatternIndices: Set<Int> = []
    private(set) var state: ShowtimeState = .intro
    private(set) var isControllerConnected: Bool
    @ObservationIgnored private let chordLabels: [Int: String]
    @ObservationIgnored private let demo: any SongDemoPlayer
    @ObservationIgnored private let gameplay: any SongGameplay
    @ObservationIgnored private let onBack: () -> Void
    @ObservationIgnored private var connectionPauseTask: Task<Void, Never>?
    @ObservationIgnored private var demoTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var started = false

    init(song: Song, demo: any SongDemoPlayer, gameplay: any SongGameplay,
         onBack: @escaping () -> Void) {
        timeline = SongTimeline(song: song)
        previewPatterns = SongTimeline(song: song).previewPatterns
        chordLabels = SongTimeline(song: song).chordLabels
        self.demo = demo; self.gameplay = gameplay; self.onBack = onBack
        isControllerConnected = gameplay.isControllerConnected
        gameplay.onStateChanged = { [weak self] in self?.receiveGameplay($0) }
        gameplay.onConnectionChanged = { [weak self] connected in
            guard let self else { return }
            self.isControllerConnected = connected
            if !connected {
                self.connectionPauseTask?.cancel()
                self.connectionPauseTask = Task { [weak self] in
                    guard !Task.isCancelled else { return }
                    await self?.send(.pause(.connection))
                }
            }
        }
    }
    var isListening: Bool {
        switch state {
        case .intro, .listening, .ready, .paused(.listening, _), .paused(.ready, _): true
        default: false
        }
    }
    var hasPreviewedAllPatterns: Bool { completedPatternIndices.count == previewPatterns.count }
    var canReady: Bool { state == .ready && hasPreviewedAllPatterns }
    var previewPattern: StrumPattern { previewPatterns[selectedPatternIndex] }
    var isAnimating: Bool {
        switch state {
        case .listening, .ready, .countIn, .playing: true
        default: false
        }
    }
    func appear() {
        guard !started else { return }
        started = true
        gameplay.onAppear()
    }
    private func startPreview() async {
        demoTask?.cancel()
        let events = demo.events // A fresh subscription drops callbacks from a previous run.
        demoTask = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled, let self else { return }
                switch event {
                case .step(let index):
                    switch self.state {
                    case .listening, .ready:
                        self.previewStep = index
                        self.state = reduce(self.state, .previewStep(index))
                    default: break
                    }
                case .finished: self.completeSelectedPattern()
                }
            }
        }
        previewStep = 0
        await demo.start(pattern: previewPattern, bpm: timeline.song.bpm)
    }
    /// Only a full loop from the current preview run counts, including a completion queued before Pause.
    private func completeSelectedPattern() {
        switch state {
        case .listening, .ready, .paused(.listening, _), .paused(.ready, _): break
        default: return
        }
        completedPatternIndices.insert(selectedPatternIndex)
        if hasPreviewedAllPatterns { state = reduce(state, .previewFinished) }
    }
    func disappear() async {
        generation += 1
        connectionPauseTask?.cancel(); connectionPauseTask = nil
        demoTask?.cancel(); demoTask = nil
        await demo.stop()
        await gameplay.onDisappear()
        started = false
    }
    func send(_ event: ShowtimeEvent) async {
        if case .previewFinished = event {
            completeSelectedPattern()
            return
        }
        // A connection alert can already have been set by the gameplay callback.
        // Muting must still happen even if the pause state itself does not change.
        if case .pause(.connection) = event, case .paused(_, .connection) = state {
            await demo.pause()
            return
        }
        if case .selectPattern(let index) = event {
            guard previewPatterns.indices.contains(index), index != selectedPatternIndex else { return }
            switch state {
            case .listening, .ready: break
            default: return
            }
            selectedPatternIndex = index
            state = reduce(state, event)
            if hasPreviewedAllPatterns { state = reduce(state, .previewFinished) }
            generation += 1
            let run = generation
            demoTask?.cancel()
            await demo.stop()
            guard generation == run else { return }
            await startPreview()
            return
        }
        // All patterns must be heard once; gameplay additionally needs a connected iPhone.
        if case .ready = event, !canReady { return }
        if case .ready = event, !isControllerConnected {
            await send(.pause(.connection))
            return
        }
        if case .resume = event, case .paused(_, .connection) = state, !isControllerConnected { return }
        if case .restart = event, case .paused(.playing, _) = state, !isControllerConnected { return }
        if case .restart = event, case .paused(.countIn, _) = state, !isControllerConnected { return }
        let previous = state
        let next = reduce(previous, event)
        guard next != previous else { return }
        state = next
        generation += 1
        let run = generation
        switch event {
        case .next:
            await startPreview()
        case .ready:
            demoTask?.cancel()
            await demo.stop()
            guard generation == run else { return }
            await gameplay.send(.tapReady)
        case .pause:
            if isListening { await demo.pause() }
            else { await gameplay.send(.tapPause) }
        case .resume:
            if case .paused(.listening, _) = previous { await demo.resume() }
            else if case .paused(.ready, _) = previous { await demo.resume() }
            else { await gameplay.send(.tapResume) }
        case .restart:
            demoTask?.cancel()
            await demo.stop()
            guard generation == run else { return }
            if case .listening = next {
                completedPatternIndices.removeAll()
                selectedPatternIndex = 0
                await gameplay.send(.tapRestart)
                guard generation == run else { return }
                await startPreview()
            } else { await gameplay.send(.tapRestart) }
        case .back:
            demoTask?.cancel()
            completedPatternIndices.removeAll()
            await demo.stop()
            await gameplay.send(.tapPause)
            await gameplay.send(.tapBackToMenu)
            await gameplay.onDisappear()
            // Drop unfinished in-memory results by leaving the session; nothing is saved here.
            onBack()
        default: break
        }
    }
    /// Called by the shared engine, independently of SwiftUI rendering.
    func receiveGameplay(_ phase: PracticeState) {
        switch phase {
        case .countIn(let number): state = reduce(state, .countdown(number))
        case .playing: state = reduce(state, .firstBeat)
        case .paused: state = reduce(state, .pause(.user))
        case .disconnected: state = reduce(state, .pause(.connection))
        case .finished(let result):
            state = reduce(state, .completed(result))
        default: break
        }
    }
    func playFrame() -> PlayScreenModel {
        var frame = gameplay.screenModel()
        frame.chordLabels = chordLabels
        frame.titleLines = TitleLineWrapping.lines(for: timeline.song.title)
        // Before the first clock tick, briefly show the same READY? callout as Practice.
        if case .countIn = state, frame.songTime <= -6 * timeline.slotInterval { frame = readyFrame(frame) }
        return frame
    }
    private func readyFrame(_ frame: PlayScreenModel) -> PlayScreenModel {
        PlayScreenModel(title: frame.title, bpm: frame.bpm, duration: frame.duration,
            slotInterval: frame.slotInterval, songTime: frame.songTime, phase: .ready,
            nodes: frame.nodes, lastJudgement: nil, readyLeadTime: 0, chordLabels: frame.chordLabels, titleLines: frame.titleLines)
    }
}
