import Foundation
import Observation

@MainActor
@Observable
final class ListenViewModel {
    let pattern: StrumPattern
    let bpm: Int
    private(set) var state: ListenState = .information
    @ObservationIgnored private let player: ListenPatternPlayer
    @ObservationIgnored private let history: any SessionHistoryChecking
    @ObservationIgnored private let guidanceStore: any PracticeGuidanceStore
    @ObservationIgnored private let onReady: () -> Void
    @ObservationIgnored private let onBack: () -> Void
    @ObservationIgnored private var progressTask: Task<Void, Never>?
    @ObservationIgnored private var historyTask: Task<Void, Never>?

    init(pattern: StrumPattern, bpm: Int, player: ListenPatternPlayer,
         history: (any SessionHistoryChecking)? = nil,
         guidanceStore: any PracticeGuidanceStore,
         onReady: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.pattern = pattern
        self.bpm = bpm
        self.player = player
        self.history = history ?? UnavailableSessionRepository()
        self.guidanceStore = guidanceStore
        self.onReady = onReady
        self.onBack = onBack
    }

    convenience init(pattern: StrumPattern, bpm: Int, player: ListenPatternPlayer,
                     history: (any SessionHistoryChecking)? = nil,
                     onReady: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.init(pattern: pattern, bpm: bpm, player: player, history: history,
                  guidanceStore: UserDefaultsPracticeGuidanceStore(),
                  onReady: onReady, onBack: onBack)
    }

    func send(_ event: ListenEvent) {
        let previous = state
        let actualEvent: ListenEvent
        if case .next = event, previous == .information, !guidanceStore.hasCompletedGuidance {
            actualEvent = .showGuidance
        } else {
            actualEvent = event
        }
        state = reduce(state, actualEvent)
        switch actualEvent {
        case .next where previous == .information:
            startPlayback()
        case .showGuidance:
            break
        case .instructionsNext:
            if case .instructions = previous {
                guidanceStore.completeGuidance()
                startPlayback()
            }
        case .ready:
            if case .departed = state {
                stop()
                onReady()
            }
        case .restart where state != previous:
            startPlayback()
        case .pause:
            if case .paused = state { player.pause(); progressTask?.cancel() }
        case .resume:
            if case .paused = previous { player.resume(); observeProgress() }
        case .retryHistory:
            if case .checkingHistory = state, state != previous { checkHistory() }
        case .historyChecked(let hasRecords):
            if hasRecords, case .checkingHistory = previous, state == .departed {
                stop(); onReady()
            }
        case .back where previous != .departed:
            stop(); onBack()
        default: break
        }
    }

    func refreshProgress() {
        guard case .listening = state, !pattern.strokes.isEmpty else { return }
        let loopDuration = Double(pattern.beatsPerPattern) * 60 / Double(bpm)
        let steps = Int(player.elapsed / (loopDuration / Double(pattern.strokes.count)))
        send(.progress(step: steps % pattern.strokes.count, completed: player.elapsed >= loopDuration))
    }

    func stop() {
        progressTask?.cancel(); progressTask = nil
        historyTask?.cancel(); historyTask = nil
        player.stop()
    }

    private func checkHistory() {
        stop()
        historyTask = Task { [weak self, history] in
            do {
                let hasRecords = try await history.hasSavedSessions()
                try Task.checkCancellation()
                self?.send(.historyChecked(hasRecords: hasRecords))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.send(.historyCheckFailed("Your practice history couldn’t be checked. Please try again."))
            }
        }
    }

    private func startPlayback() {
        progressTask?.cancel()
        do {
            try player.start(pattern: pattern, bpm: bpm)
            observeProgress()
        } catch {
            player.stop()
            state = reduce(state, .failed("The guitar example couldn’t play. Please try again."))
        }
    }

    private func observeProgress() {
        progressTask?.cancel()
        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refreshProgress()
                do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
            }
        }
    }
}
