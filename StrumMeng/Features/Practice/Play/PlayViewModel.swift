import Foundation
import Observation

/// The game loop of one practice session: Ready, 3-2-1 count-in, play, judge, finish.
///
/// BeatClock ticks (one per pattern step, delivered on time) drive the session; strums come from
/// StrumInputService (on-screen swipes, or the iPhone controller link). FeedbackEngine turns them into BeatEvents the moment each result is final,
/// and the screen shows them on the nodes. Every position on screen is derived from the clock's
/// tick times, so the visuals cannot drift from the beat.
@Observable
final class PlayViewModel {
    /// 3-2-1 on quarter notes = 6 steps before the first step of the session.
    static let countInSteps = 6
    /// How long to wait for an iPhone strum still on its way over Wi-Fi before closing a window.
    /// Strums are judged by touch time, but a window closed before the strum arrives would
    /// already be a Miss. Must stay well below one step (250 ms at 120 BPM).
    static let controllerStrumArrivalGrace: TimeInterval = 0.15

    let pattern: StrumPattern
    let bpm: Int

    private(set) var state: PracticeState = .ready
    private(set) var beatEvents: [BeatEvent] = []
    /// Always true without a controller. With one, a session only starts or resumes while it is true.
    private(set) var isControllerConnected = false

    var isAnimating: Bool {
        switch state {
        case .countIn, .playing: true
        default: false
        }
    }

    @ObservationIgnored private let clock: BeatClock
    @ObservationIgnored private let input: StrumInputService
    @ObservationIgnored private let touchInput: TouchStrumInput?
    @ObservationIgnored private let controller: ControllerLink?
    @ObservationIgnored private let requiresController: Bool
    /// Whether the current session started with the controller connected; only such a session
    /// pauses when the controller drops.
    @ObservationIgnored private var sessionUsesController = false
    @ObservationIgnored private let tolerance: ToleranceConfig
    @ObservationIgnored private let latencyOffset: TimeInterval
    @ObservationIgnored private let strumArrivalGrace: TimeInterval
    @ObservationIgnored private let now: () -> TimeInterval
    @ObservationIgnored private let waitUntil: (TimeInterval) async -> Void
    @ObservationIgnored private let makeID: () -> UUID
    @ObservationIgnored private let currentDate: () -> Date
    @ObservationIgnored private let onFinished: (SessionResult) -> Void
    @ObservationIgnored private let onExit: () -> Void

    @ObservationIgnored let stepInterval: TimeInterval
    @ObservationIgnored let totalSteps: Int
    @ObservationIgnored private let duration: TimeInterval
    @ObservationIgnored private let laneNodes: [PlayLaneNode]

    @ObservationIgnored private var engine: FeedbackEngine
    /// Session time (seconds after step 0) at which each step's result appeared, for the animation.
    @ObservationIgnored private var judgedAt: [Int: TimeInterval] = [:]
    /// Clock tick index of the first count-in tick of the current count-in.
    @ObservationIgnored private var countInFirstIndex: Int?
    /// tick index - step index, fixed at each count-in (it shifts after a resume).
    @ObservationIgnored private var stepOffset = countInSteps
    /// The step the next count-in leads into: 0 at the start, the first unjudged step after a pause.
    @ObservationIgnored private var resumeStep = 0
    @ObservationIgnored private var nextStep = 0
    /// Host time at which step 0 sits in the hit ring under the current mapping.
    @ObservationIgnored private var anchorTime: TimeInterval?
    /// Session time frozen while paused or finished.
    @ObservationIgnored private var frozenSongTime: TimeInterval?
    /// Session time of the latest swipe in a running session, judged or not (the ring reacts to it).
    @ObservationIgnored private var lastStrumSongTime: TimeInterval?

    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var strumTask: Task<Void, Never>?
    @ObservationIgnored private var windowTask: Task<Void, Never>?
    @ObservationIgnored private var controllerTask: Task<Void, Never>?

    /// - Parameters:
    ///   - controller: the iPhone link when it is the strum source. The view model tells it when a
    ///     session is running and pauses when it disconnects. Pass the same link as `input` (or
    ///     merged into it).
    ///   - requiresController: true when the controller is the only input, so Ready and Resume
    ///     wait for it. False when on-screen swipes work too: the player may start without the
    ///     iPhone, and only a session started with it pauses when it drops.
    ///   - strumArrivalGrace: extra time a window stays open for strums that arrive late (network
    ///     delay); 0 for on-screen swipes, controllerStrumArrivalGrace for the iPhone.
    ///   - repetitions: how many times the pattern repeats (PracticeSessionConfig).
    ///   - latencyOffset: from calibration (SettingsStore, later); applied only inside TimingJudge.
    ///   - now: the host clock.
    ///   - waitUntil: suspends until a host-clock time; injected so tests control time.
    init(pattern: StrumPattern,
         bpm: Int,
         clock: BeatClock,
         input: StrumInputService,
         touchInput: TouchStrumInput?,
         controller: ControllerLink? = nil,
         requiresController: Bool = true,
         tolerance: ToleranceConfig = .standard,
         latencyOffset: TimeInterval = 0,
         strumArrivalGrace: TimeInterval = 0,
         repetitions: Int = PracticeSessionConfig.patternRepetitions,
         now: @escaping () -> TimeInterval,
         waitUntil: @escaping (TimeInterval) async -> Void,
         makeID: @escaping () -> UUID = UUID.init,
         currentDate: @escaping () -> Date = Date.init,
         onFinished: @escaping (SessionResult) -> Void = { _ in },
         onExit: @escaping () -> Void = {}) {
        self.pattern = pattern
        self.bpm = bpm
        self.clock = clock
        self.input = input
        self.touchInput = touchInput
        self.controller = controller
        self.requiresController = requiresController
        isControllerConnected = controller == nil
        self.tolerance = tolerance
        self.latencyOffset = latencyOffset
        self.strumArrivalGrace = strumArrivalGrace
        self.now = now
        self.waitUntil = waitUntil
        self.makeID = makeID
        self.currentDate = currentDate
        self.onFinished = onFinished
        self.onExit = onExit

        stepInterval = AudioBeatClock.stepInterval(bpm: bpm)
        totalSteps = pattern.strokes.count * max(1, repetitions)
        duration = Double(totalSteps) * stepInterval
        laneNodes = PlayTimeline.makeNodes(pattern: pattern.strokes.map(Self.arrow(for:)),
                                           slotInterval: stepInterval, duration: duration)
        engine = FeedbackEngine(config: tolerance, latencyOffset: latencyOffset, stepInterval: stepInterval)
    }

    // MARK: Lifecycle

    func onAppear() {
        tickTask?.cancel()
        strumTask?.cancel()
        let ticks = clock.beatStream
        let strums = input.strums
        tickTask = Task { [weak self] in
            for await tick in ticks { self?.handle(tick) }
        }
        strumTask = Task { [weak self] in
            for await strum in strums { self?.handle(strum) }
        }
        controllerTask?.cancel()
        if let states = controller?.connectionStates {
            controllerTask = Task { [weak self] in
                for await connection in states { await self?.handle(connection) }
            }
        }
    }

    /// Leaving the screen discards an unfinished session and stops every task.
    func onDisappear() async {
        [tickTask, strumTask, windowTask, controllerTask].forEach { $0?.cancel() }
        await clock.stop()
        await controller?.setSessionActive(false)
    }

    // MARK: Events from the View

    func send(_ event: PracticeEvent) async {
        let previous = state
        let next = reduce(previous, event)
        guard next != previous else { return }
        // Counting in without the only input connected would only collect Misses.
        if case .countIn = next, requiresController, !isControllerConnected { return }
        state = next
        if case .countIn = state {
            sessionUsesController = controller != nil && isControllerConnected
        }

        switch (event, state) {
        case (.tapReady, .countIn), (.tapRestart, .countIn):
            resetSession()
            await controller?.setSessionActive(true)
            await clock.start(bpm: bpm)
        case (.tapResume, .countIn):
            countInFirstIndex = nil
            await controller?.setSessionActive(true)
            await clock.resume()
        case (_, .paused):
            await controller?.setSessionActive(false)
            await pause()
        case (.tapRestart, .ready):
            resetSession()
        case (.tapBackToMenu, .idle):
            resetSession()
            await clock.stop()
            onExit()
        default:
            break
        }
    }

    /// The longest believable gap between a touch and its handling. A bigger (or negative) gap means
    /// the event timestamp is not on the wall clock, so it is ignored rather than trusted.
    static let maxTouchDelay: TimeInterval = 0.1

    /// - Parameter eventDate: the touch event's own timestamp. When it is plausible, it is turned into
    ///   host-clock time so a strum keeps its real time even if the main thread handled it a little
    ///   late; otherwise the strum is timed now.
    func dragChanged(translation: Double, eventDate: Date) {
        let delay = currentDate().timeIntervalSince(eventDate)
        let usable = (0...Self.maxTouchDelay).contains(delay) ? delay : 0
        touchInput?.dragChanged(translation: translation, at: now() - usable)
    }

    func dragEnded() {
        touchInput?.dragEnded()
    }

    // MARK: Inputs from services (internal so tests can drive them directly)

    func handle(_ tick: BeatTick) {
        switch state {
        case .countIn:
            let first = countInFirstIndex ?? tick.index
            if countInFirstIndex == nil {
                countInFirstIndex = first
                stepOffset = first + Self.countInSteps - resumeStep
                frozenSongTime = nil
            }
            anchorTime = tick.expectedTime - Double(tick.index - stepOffset) * stepInterval
            let position = tick.index - first
            if position < Self.countInSteps {
                if position > 0, position.isMultiple(of: 2) {
                    state = reduce(state, .countInTick)
                }
                return
            }
            state = reduce(state, .countInDone)
            playStep(tick)
        case .playing:
            anchorTime = tick.expectedTime - Double(tick.index - stepOffset) * stepInterval
            playStep(tick)
        default:
            break
        }
    }

    /// Strums count during the count-in too, because the first beat's early window starts before
    /// step 0. Outside a running session they are ignored, not judged.
    func handle(_ strum: StrumEvent) {
        switch state {
        case .countIn, .playing:
            // The ring reacts when the strum arrives, not at its touch time: an iPhone strum can
            // arrive after the short pulse would already be over, so it would look undetected.
            // Judging still uses the touch time.
            if anchorTime != nil { lastStrumSongTime = currentSongTime() }
            apply(engine.addStrum(strum))
            finishIfDone()
        default:
            break
        }
    }

    /// A controller that stops being connected while counting in or playing pauses the session,
    /// instead of judging the strums it can no longer send as Miss.
    func handle(_ connection: ControllerConnectionState) async {
        if case .connected = connection {
            // Arrives with every ping; only a real change should notify observers.
            if !isControllerConnected { isControllerConnected = true }
            return
        }
        isControllerConnected = false
        // A session played on the iPad screen alone carries on without the iPhone.
        guard requiresController || sessionUsesController else { return }
        await send(.controllerDisconnected)
    }

    /// Judges every beat whose window ended before `time`, minus the arrival grace: a strum
    /// touched inside a window may still be on its way.
    func closeWindows(upTo time: TimeInterval) {
        apply(engine.close(upTo: time - strumArrivalGrace))
        finishIfDone()
    }

    // MARK: Screen

    /// Everything the Play screen draws right now.
    func screenModel() -> PlayScreenModel {
        let songTime = currentSongTime()
        var nodes = laneNodes
        var last: PlayJudgement?
        for event in beatEvents where nodes.indices.contains(event.stepIndex) {
            let judgement = PlayJudgement(feedback: PlayFeedback(event.result),
                                          time: judgedAt[event.stepIndex] ?? songTime)
            nodes[event.stepIndex].judgement = judgement
            if judgement.time <= songTime, judgement.time > last?.time ?? -.infinity {
                last = judgement
            }
        }
        return PlayScreenModel(title: pattern.name, bpm: bpm, duration: duration,
                               slotInterval: stepInterval, songTime: songTime, phase: phase,
                               nodes: nodes, lastJudgement: last, lastStrumTime: lastStrumSongTime)
    }

    private var phase: PlayScreenPhase {
        switch state {
        case .idle, .listening, .ready: .ready
        case .countIn(let n): .countIn(n)
        case .playing, .finished: .playing
        case .paused: .paused
        }
    }

    private func currentSongTime() -> TimeInterval {
        if let frozenSongTime { return frozenSongTime }
        if let anchorTime { return now() - anchorTime }
        return -Double(Self.countInSteps) * stepInterval
    }

    // MARK: Game loop

    private func playStep(_ tick: BeatTick) {
        let step = tick.index - stepOffset
        apply(engine.close(upTo: tick.expectedTime - strumArrivalGrace))
        if step < totalSteps {
            nextStep = step + 1
            if let direction = Self.direction(for: pattern.strokes[step % pattern.strokes.count]) {
                apply(engine.addBeat(BeatTarget(index: step, expectedTime: tick.expectedTime,
                                                direction: direction)))
            }
            armWindowTimer()
        } else {
            nextStep = totalSteps
        }
        finishIfDone()
    }

    private func apply(_ events: [BeatEvent]) {
        guard !events.isEmpty else { return }
        let songTime = currentSongTime()
        for event in events {
            judgedAt[event.stepIndex] = songTime
        }
        beatEvents.append(contentsOf: events)
    }

    /// Wakes up when the oldest open window closes, so a Too Early or Miss colour does not wait
    /// for the next tick (which can be far away during rests).
    private func armWindowTimer() {
        windowTask?.cancel()
        guard let deadline = engine.nextDeadline else { return }
        windowTask = Task { [weak self, waitUntil, strumArrivalGrace] in
            await waitUntil(deadline + strumArrivalGrace)
            guard !Task.isCancelled, let self else { return }
            self.closeWindows(upTo: self.now())
            self.armWindowTimer()
        }
    }

    private func finishIfDone() {
        guard state == .playing, nextStep >= totalSteps, engine.openBeats.isEmpty else { return }
        windowTask?.cancel()
        frozenSongTime = currentSongTime()
        let result = SessionResultBuilder.build(id: makeID(), patternID: pattern.id, bpm: bpm,
                                                beatEvents: beatEvents, createdAt: currentDate())
        state = reduce(state, .sessionEnded(result))
        Task { [clock, controller] in
            await clock.stop()
            await controller?.setSessionActive(false)
        }
        onFinished(result)
    }

    private func pause() async {
        windowTask?.cancel()
        await clock.pause()
        frozenSongTime = currentSongTime()
        apply(engine.close(upTo: now() - strumArrivalGrace))
        // Beats still open when the player paused are played again after the re-count.
        let dropped = engine.discardOpenBeats()
        resumeStep = dropped.first?.index ?? nextStep
        nextStep = resumeStep
        anchorTime = nil
        countInFirstIndex = nil
    }

    private func resetSession() {
        windowTask?.cancel()
        engine = FeedbackEngine(config: tolerance, latencyOffset: latencyOffset, stepInterval: stepInterval)
        beatEvents = []
        judgedAt = [:]
        countInFirstIndex = nil
        stepOffset = Self.countInSteps
        resumeStep = 0
        nextStep = 0
        anchorTime = nil
        frozenSongTime = nil
        lastStrumSongTime = nil
    }

    /// The direction a step must be strummed in; nil for a rest, which is never judged.
    private static func direction(for stroke: Stroke) -> StrumDirection? {
        switch stroke {
        case .down: .down
        case .up: .up
        case .rest: nil
        }
    }

    nonisolated private static func arrow(for stroke: Stroke) -> BeatNodeView.Arrow? {
        switch stroke {
        case .down: .down
        case .up: .up
        case .rest: nil
        }
    }
}
