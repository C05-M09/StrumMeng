#if DEBUG
import SwiftUI

/// DEBUG-only: the real Play screen with the iPhone controller as the only strum input, to check
/// that controller strumming is feasible before the Listen → Play routing and connect screens
/// exist. Launch the iPad once with -playWithController (optionally -playPattern <id> -playBPM <n>);
/// it stays on until the status bar's App button. The status bar also shows the Bonjour pair code
/// and sets the latency offset, by hand or with a calibration round (a stand-in for the real calibration in Option until it exists).
/// Lives in App because only the composition layer may build concrete services.
struct ControllerPlayDebugView: View {
    private static let latencyKey = "debug.latencyOffsetMs"
    /// Calibration in the real app will clamp too; this keeps a wrong Auto from going wild.
    private static let latencyRangeMs = -200...200
    /// Calibration round: plain down-strums on every quarter note, at a comfortable tempo.
    private static let calibrationPatternID = "foundation"
    private static let calibrationBPM = 80
    /// Foundation has 4 strums per repetition: 4 × 4 = 16 strums.
    private static let calibrationRepetitions = 4

    /// Back to the normal app (the pattern list).
    let onLeave: () -> Void

    /// One link for the whole launch, as in the real app: sessions come and go, the link stays.
    @State private var link: any ControllerLink = BonjourControllerLink(
        pairCode: ControllerLinkDebugModel.savedHostPairCode())
    /// Built once, and again after Back to Menu; never on a redraw.
    @State private var viewModel: PlayViewModel?
    @State private var unknownPattern = false
    /// Positive = the player's strums register late (TimingJudge subtracts it). Kept per device.
    @State private var latencyMs = UserDefaults.standard.integer(forKey: Self.latencyKey)
    @State private var isCalibrating = false
    /// Offsets of the calibration round's strums from the nearest quarter note, before any latency.
    @State private var calibrationOffsets: [TimeInterval] = []
    @State private var calibrationMessage: String?

    var body: some View {
        // ZStack over a clear base: an empty Group would never appear, so onAppear and the task
        // below would never run.
        ZStack {
            Color.clear
            if let viewModel {
                PracticePlaySessionView(viewModel: viewModel)
                    .id(ObjectIdentifier(viewModel))
                    // The status is its own view: its frequent updates (every ping and strum)
                    // must not redraw the Play screen underneath.
                    .overlay(alignment: .bottom) {
                        ControllerStatusBar(link: link, viewModel: viewModel,
                                            latencyMs: latencyMs, isCalibrating: isCalibrating,
                                            calibrationMessage: calibrationMessage,
                                            onSetLatency: setLatency, onCalibrate: startCalibration,
                                            onLeave: leave)
                    }
            } else if unknownPattern {
                Text("Unknown pattern id")
            }
        }
        .onAppear {
            if viewModel == nil { startNewSession() }
        }
        .task {
            try? await link.start()
        }
        .task {
            for await strum in link.strums { collectCalibration(strum) }
        }
    }

    /// The offset is fixed for a session, so a new value starts a fresh one. The status bar only
    /// allows it while no session is running.
    private func setLatency(_ ms: Int) {
        let clamped = min(max(ms, Self.latencyRangeMs.lowerBound), Self.latencyRangeMs.upperBound)
        guard clamped != latencyMs else { return }
        latencyMs = clamped
        UserDefaults.standard.set(clamped, forKey: Self.latencyKey)
        calibrationMessage = nil
        startNewSession()
    }

    // MARK: Calibration round

    private func startCalibration() {
        guard let pattern = PatternCatalog.pattern(forID: Self.calibrationPatternID) else { return }
        isCalibrating = true
        calibrationOffsets = []
        calibrationMessage = "Calibration: tap READY?, then swipe DOWN on every beat (16 strums)"
        // Measured with no latency offset, so the offsets are the raw ones.
        viewModel = makeViewModel(pattern: pattern, bpm: Self.calibrationBPM,
                                  repetitions: Self.calibrationRepetitions, latencyMs: 0,
                                  onFinished: { _ in finishCalibration() },
                                  onExit: cancelCalibration)
    }

    private func collectCalibration(_ strum: StrumEvent) {
        guard isCalibrating, let viewModel, viewModel.isAnimating else { return }
        let model = viewModel.screenModel()
        // Song time of the touch, independent of whether PlayViewModel has handled it yet.
        let songTime = strum.time - HostClock.now() + model.songTime
        // Strums during the 3-2-1 are warm-up, not aimed at a beat of the round.
        guard songTime > -LatencyCalibrator.maxOffset else { return }
        // Foundation strums on every other step: the quarter notes.
        let offset = LatencyCalibrator.offset(ofStrumAt: songTime, beatInterval: model.slotInterval * 2)
        calibrationOffsets.append(offset)
    }

    private func finishCalibration() {
        guard isCalibrating else { return }
        isCalibrating = false
        let count = calibrationOffsets.count
        if let estimate = LatencyCalibrator.estimate(from: calibrationOffsets) {
            // Rounded to 5 ms: finer than that is noise.
            let ms = Int((estimate * 1000 / 5).rounded()) * 5
            latencyMs = min(max(ms, Self.latencyRangeMs.lowerBound), Self.latencyRangeMs.upperBound)
            UserDefaults.standard.set(latencyMs, forKey: Self.latencyKey)
            calibrationMessage = String(format: "Calibrated: latency %+d ms from %d strums", latencyMs, count)
        } else {
            calibrationMessage = "Calibration needs \(LatencyCalibrator.minimumSamples)+ strums near the beat "
                + "(got \(count)). Try again."
        }
        startNewSession()
    }

    private func cancelCalibration() {
        isCalibrating = false
        calibrationMessage = "Calibration cancelled"
        startNewSession()
    }

    private func leave() {
        let current = link
        Task { await current.stop() }
        onLeave()
    }

    private func startNewSession() {
        let defaults = UserDefaults.standard
        let patternID = defaults.string(forKey: "playPattern") ?? "syncopation"
        // Launch arguments arrive as strings; integer(forKey:) parses them and gives 0 when absent.
        let requestedBPM = defaults.integer(forKey: "playBPM")
        let bpm = requestedBPM > 0 ? requestedBPM : 80
        guard let pattern = PatternCatalog.all.first(where: { $0.id == patternID }) else {
            unknownPattern = true
            return
        }
        viewModel = makeViewModel(pattern: pattern, bpm: bpm,
                                  repetitions: PracticeSessionConfig.patternRepetitions,
                                  latencyMs: latencyMs, onFinished: { _ in },
                                  onExit: { startNewSession() })
    }

    private func makeViewModel(pattern: StrumPattern, bpm: Int, repetitions: Int, latencyMs: Int,
                               onFinished: @escaping (SessionResult) -> Void,
                               onExit: @escaping () -> Void) -> PlayViewModel {
        // Swipes on the iPad screen keep working next to the iPhone, so the iPhone is optional.
        let touch = TouchStrumInputService()
        return PlayViewModel(
            pattern: pattern, bpm: bpm, clock: AudioBeatClock(),
            input: MergedStrumInputService(sources: [link, touch]), touchInput: touch,
            controller: link, requiresController: false,
            latencyOffset: Double(latencyMs) / 1000,
            strumArrivalGrace: PlayViewModel.controllerStrumArrivalGrace,
            repetitions: repetitions,
            now: HostClock.now,
            waitUntil: { time in
                let delay = time - HostClock.now()
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            },
            onFinished: onFinished,
            onExit: onExit)
    }
}

/// Connection and per-strum diagnostics. Splits a Miss into its two possible causes:
/// the strum never arrived (the iPhone's sent count is higher than "Received") or it arrived but
/// was off the beat (the offset shown here).
private struct ControllerStatusBar: View {
    let link: any ControllerLink
    let viewModel: PlayViewModel
    let latencyMs: Int
    let isCalibrating: Bool
    let calibrationMessage: String?
    let onSetLatency: (Int) -> Void
    let onCalibrate: () -> Void
    let onLeave: () -> Void

    /// Strums Auto looks at: enough to smooth out a few sloppy ones, recent enough to follow a change.
    private static let recentLimit = 16
    private static let latencyStepMs = 10

    @State private var connection: ControllerConnectionState = .unpaired
    /// Strums received since the last start or resume; the iPhone resets its sent count then too.
    @State private var receivedCount = 0
    @State private var lastStrumInfo = "no strum yet"
    /// Raw offsets (before the latency offset) of recent strums, for Auto.
    @State private var recentRawOffsetsMs: [Double] = []

    var body: some View {
        HStack(spacing: AppSpacing.s) {
            VStack(spacing: 0) {
                Text("Pair code \(link.pairCode.value) · \(connectionText)")
                Text("Received \(receivedCount) · \(lastStrumInfo)")
                if let calibrationMessage { Text(calibrationMessage) }
                if !isCalibrating { latencyRow }
            }
            .font(.caption.monospaced())
            .multilineTextAlignment(.center)
            Button("App", action: onLeave)
        }
        .font(.caption)
        .foregroundStyle(AppColor.ink)
        .padding(.horizontal, AppSpacing.m)
        .padding(.vertical, AppSpacing.xs)
        // Opaque on purpose: a blur over the moving board is re-rendered every frame.
        .background(AppColor.paper, in: Capsule())
        .padding(.bottom, AppSpacing.s)
        .onChange(of: viewModel.state) { old, new in
            if case .countIn = new, !Self.isCountIn(old) { receivedCount = 0 }
        }
        .task {
            for await state in link.connectionStates { connection = state }
        }
        .task {
            for await strum in link.strums { record(strum) }
        }
    }

    /// Shift the judge's idea of "on time" until the strums land on the beat. Auto uses the median
    /// of recent strums, so one sloppy strum does not move it much.
    private var latencyRow: some View {
        let running = viewModel.isAnimating
        let median = Self.median(recentRawOffsetsMs)
        return HStack(spacing: AppSpacing.s) {
            Text(String(format: "Latency %+d ms", latencyMs))
            Button("−\(Self.latencyStepMs)") { onSetLatency(latencyMs - Self.latencyStepMs) }
            Button("+\(Self.latencyStepMs)") { onSetLatency(latencyMs + Self.latencyStepMs) }
            if latencyMs != 0 {
                Button("Reset") { onSetLatency(0) }
            }
            if let median {
                Button(String(format: "Auto %+.0f", median)) {
                    // Rounded to 5 ms: finer than that is noise.
                    onSetLatency(Int((median / 5).rounded()) * 5)
                }
            }
            Button("Calibrate", action: onCalibrate)
        }
        .disabled(running)
        .opacity(running ? 0.5 : 1)
    }

    private static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    private var connectionText: String {
        switch connection {
        case .unpaired: "Not started"
        case .pairing: "Pairing…"
        case .searching: "Waiting for iPhone"
        case .reconnecting: "iPhone lost, reconnecting…"
        case let .connected(latencyMs): "iPhone connected, \(String(format: "%.1f", latencyMs)) ms"
        }
    }

    private func record(_ strum: StrumEvent) {
        guard viewModel.isAnimating else { return }
        receivedCount += 1
        let now = HostClock.now()
        let model = viewModel.screenModel()
        // Song time of the touch, independent of whether PlayViewModel has handled it yet.
        let strumSongTime = strum.time - now + model.songTime
        let nearestStep = (strumSongTime / model.slotInterval).rounded() * model.slotInterval
        let rawOffsetMs = (strumSongTime - nearestStep) * 1000
        recentRawOffsetsMs = Array((recentRawOffsetsMs + [rawOffsetMs]).suffix(Self.recentLimit))
        // What the judge sees: the raw offset minus the latency offset.
        let judgedOffsetMs = rawOffsetMs - Double(latencyMs)
        let arrivalMs = (now - strum.time) * 1000
        lastStrumInfo = String(format: "last %@ %+.0f ms vs beat, arrived %.0f ms after touch",
                               strum.direction == .down ? "↓" : "↑", judgedOffsetMs, arrivalMs)
    }

    private static func isCountIn(_ state: PracticeState) -> Bool {
        if case .countIn = state { return true }
        return false
    }
}
#endif
