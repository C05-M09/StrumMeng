import Foundation
import Observation

@MainActor
@Observable
final class ListenViewModel {
    let pattern: StrumPattern
    let bpm: Int
    private(set) var state: ListenState = .information
    @ObservationIgnored private let player: ListenPatternPlayer
    @ObservationIgnored private let onReady: () -> Void
    @ObservationIgnored private let onBack: () -> Void
    @ObservationIgnored private var progressTask: Task<Void, Never>?

    init(pattern: StrumPattern, bpm: Int, player: ListenPatternPlayer,
         onReady: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.pattern = pattern
        self.bpm = bpm
        self.player = player
        self.onReady = onReady
        self.onBack = onBack
    }

    func send(_ event: ListenEvent) {
        let previous = state
        state = reduce(state, event)
        switch event {
        case .next where previous == .information:
            startPlayback()
        case .restart where state != previous:
            startPlayback()
        case .pause:
            if case .paused = state { player.pause(); progressTask?.cancel() }
        case .resume:
            if case .paused = previous { player.resume(); observeProgress() }
        case .ready where previous.canProceed:
            stop(); onReady()
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

    func stop() { progressTask?.cancel(); progressTask = nil; player.stop() }

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
