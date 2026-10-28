#if DEBUG
import SwiftUI

/// DEBUG-only: the real Play screen with the iPhone controller as the only strum input, to check
/// that controller strumming is feasible before the Listen → Play routing and connect screens
/// exist. Launch the iPad with -playWithController (optionally -playPattern <id> -playBPM <n>).
/// Lives in App because only the composition layer may build concrete services.
struct ControllerPlayDebugView: View {
    /// One link for the whole launch, as in the real app: sessions come and go, the link stays.
    @State private var link = BonjourControllerLink(pairCode: ControllerLinkDebugModel.savedHostPairCode())
    /// Built once, and again after Back to Menu; never on a redraw.
    @State private var viewModel: PlayViewModel?
    @State private var unknownPattern = false

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
                    .overlay(alignment: .bottom) { ControllerStatusBar(link: link, viewModel: viewModel) }
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
        viewModel = PlayViewModel(
            pattern: pattern, bpm: bpm, clock: AudioBeatClock(), input: link, touchInput: nil,
            controller: link,
            strumArrivalGrace: PlayViewModel.controllerStrumArrivalGrace,
            now: HostClock.now,
            waitUntil: { time in
                let delay = time - HostClock.now()
                if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            },
            onExit: { startNewSession() })
    }
}

/// Pair code, connection and per-strum diagnostics. Splits a Miss into its two possible causes:
/// the strum never arrived (the iPhone's sent count is higher than "Received") or it arrived but
/// was off the beat (the offset shown here).
private struct ControllerStatusBar: View {
    let link: BonjourControllerLink
    let viewModel: PlayViewModel

    @State private var connection: ControllerConnectionState = .unpaired
    /// Strums received since the last start or resume; the iPhone resets its sent count then too.
    @State private var receivedCount = 0
    @State private var lastStrumInfo = "no strum yet"

    var body: some View {
        Text("Pair code \(link.pairCode.value) · \(connectionText)\nReceived \(receivedCount) · \(lastStrumInfo)")
            .multilineTextAlignment(.center)
            .font(.caption.monospaced())
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
        let offsetMs = (strumSongTime - nearestStep) * 1000
        let arrivalMs = (now - strum.time) * 1000
        lastStrumInfo = String(format: "last %@ %+.0f ms vs beat, arrived %.0f ms after touch",
                               strum.direction == .down ? "↓" : "↑", offsetMs, arrivalMs)
    }

    private static func isCountIn(_ state: PracticeState) -> Bool {
        if case .countIn = state { return true }
        return false
    }
}
#endif
