import Foundation
import Observation

@MainActor
@Observable
final class ListenViewModel {
    let pattern: StrumPattern
    let bpm: Int
    private(set) var state: ListenState = .information
    /// Always true without a controller (previews, tests). With one, Ready needs it.
    private(set) var isControllerConnected: Bool
    @ObservationIgnored private let player: ListenPatternPlayer
    @ObservationIgnored private let history: any SessionHistoryChecking
    @ObservationIgnored private let guidanceStore: any PracticeGuidanceStore
    @ObservationIgnored private let onReady: () -> Void
    @ObservationIgnored private let onBack: () -> Void
    @ObservationIgnored private let controller: (any ControllerLink)?
    @ObservationIgnored private let onSetUpDevice: () -> Void
    @ObservationIgnored private var controllerTask: Task<Void, Never>?
    @ObservationIgnored private var progressTask: Task<Void, Never>?
    @ObservationIgnored private var historyTask: Task<Void, Never>?
    /// The history question asked as soon as the example starts, so Ready already knows the
    /// answer and goes on without a "Getting ready" screen. Kept until it fails.
    @ObservationIgnored private var historyLookup: Task<Bool, Error>?
    @ObservationIgnored private var knownHasRecords: Bool?

    init(pattern: StrumPattern, bpm: Int, player: ListenPatternPlayer,
         history: (any SessionHistoryChecking)? = nil,
         guidanceStore: any PracticeGuidanceStore,
         controller: (any ControllerLink)? = nil,
         onSetUpDevice: @escaping () -> Void = {},
         onReady: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.pattern = pattern
        self.bpm = bpm
        self.player = player
        self.history = history ?? UnavailableSessionRepository()
        self.guidanceStore = guidanceStore
        self.controller = controller
        self.onSetUpDevice = onSetUpDevice
        self.onReady = onReady
        self.onBack = onBack
        isControllerConnected = controller == nil
    }

    /// Follows the iPhone for as long as the screen is up.
    func appear() {
        if state == .departed {
            state = .listening(step: 0, completed: true)
            startPlayback()
        }
        guard controllerTask == nil, let states = controller?.connectionStates else { return }
        controllerTask = Task { [weak self] in
            for await connection in states { self?.handle(connection) }
        }
    }

    /// Leaving the screen: stops the example and stops following the iPhone.
    func disappear() {
        stop()
        controllerTask?.cancel()
        controllerTask = nil
    }

    func handle(_ connection: ControllerConnectionState) {
        if case .connected = connection {
            // Arrives with every ping; only a real change should notify observers.
            if !isControllerConnected { isControllerConnected = true }
            return
        }
        isControllerConnected = false
    }

    /// Set Up Device from the disconnected popup; the example stays paused underneath.
    func requestDeviceSetup() {
        guard case .disconnected = state else { return }
        onSetUpDevice()
    }

    convenience init(pattern: StrumPattern, bpm: Int, player: ListenPatternPlayer,
                     history: (any SessionHistoryChecking)? = nil,
                     guidanceStore: (any PracticeGuidanceStore)? = nil,
                     controller: (any ControllerLink)? = nil,
                     onSetUpDevice: @escaping () -> Void = {},
                     onReady: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.init(pattern: pattern, bpm: bpm, player: player, history: history,
                  guidanceStore: guidanceStore ?? UserDefaultsPracticeGuidanceStore(),
                  controller: controller,
                  onSetUpDevice: onSetUpDevice,
                  onReady: onReady, onBack: onBack)
    }

    func send(_ event: ListenEvent) {
        // Play would only collect Misses without the iPhone, so Ready waits for it here.
        if case .ready = event, state.canProceed, !isControllerConnected {
            send(.readyWithoutController)
            return
        }
        if case .resume = event, case .disconnected = state, !isControllerConnected { return }
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
            lookUpHistoryEarly()
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
            switch previous {
            case .paused, .disconnected: player.resume(); observeProgress()
            default: break
            }
        case .controllerDisconnected:
            // From the pause menu the example is already paused.
            if case .listening = previous, case .disconnected = state { player.pause(); progressTask?.cancel() }
        case .readyWithoutController:
            if case .disconnected = state, state != previous { player.pause(); progressTask?.cancel() }
        case .dismissDisconnected:
            if case .listening = state, state != previous { player.resume(); observeProgress() }
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

    private func lookUpHistoryEarly() {
        guard historyLookup == nil, knownHasRecords == nil else { return }
        let lookup = Task { [history] in try await history.hasSavedSessions() }
        historyLookup = lookup
        Task { [weak self] in
            guard let hasRecords = try? await lookup.value else { return }
            self?.knownHasRecords = hasRecords
        }
    }

    private func checkHistory() {
        stop()
        // Usually answered while the example played: decide now, in the same update as Ready.
        if let knownHasRecords {
            send(.historyChecked(hasRecords: knownHasRecords))
            return
        }
        // Otherwise wait for the question already asked (or ask it, after a failure).
        let lookup = historyLookup ?? Task { [history] in try await history.hasSavedSessions() }
        historyLookup = lookup
        historyTask = Task { [weak self] in
            do {
                let hasRecords = try await lookup.value
                try Task.checkCancellation()
                self?.knownHasRecords = hasRecords
                self?.send(.historyChecked(hasRecords: hasRecords))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                // Ask again on Try again rather than reusing the failed answer.
                self?.historyLookup = nil
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
