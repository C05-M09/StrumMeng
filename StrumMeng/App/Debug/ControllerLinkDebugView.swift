#if DEBUG
import SwiftUI

/// DEBUG-only screen for ControllerLinkDebugModel. Plain system styling on purpose: it is a test
/// tool, not part of the designed UI.
struct ControllerLinkDebugView: View {
    @State private var model: ControllerLinkDebugModel

    init(model: ControllerLinkDebugModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            List {
                Section("Connection") {
                    LabeledContent("State", value: stateText)
                    LabeledContent("Session", value: model.sessionActive ? "Playing" : "Not playing")
                    if model.role == .controller {
                        LabeledContent("Strums sent", value: "\(model.sentCount)")
                    }
                }
                switch model.role {
                case .host:
                    hostSection
                case .controller:
                    controllerSection(enteredCode: $model.enteredCode)
                }
                Section("Log") {
                    ForEach(Array(model.log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle(model.role == .host ? "Link test: iPad" : "Link test: iPhone")
        }
        .onAppear { model.appear() }
        .onDisappear { model.disappear() }
    }

    private var hostSection: some View {
        Section("iPad") {
            LabeledContent("Pair code", value: model.hostPairCode?.value ?? "-")
            Button(model.sessionActive ? "Stop session" : "Start session") { model.toggleSession() }
        }
    }

    private func controllerSection(enteredCode: Binding<String>) -> some View {
        Section("iPhone") {
            TextField("6-digit code from the iPad", text: enteredCode)
                .keyboardType(.numberPad)
            Button("Connect") { model.connectTapped() }
            HStack(spacing: AppSpacing.m) {
                Button("Strum down") { model.strum(.down) }
                    .buttonStyle(.borderedProminent)
                Button("Strum up") { model.strum(.up) }
                    .buttonStyle(.borderedProminent)
            }
            swipePad
        }
    }

    /// Swipe up or down here to strum, like the real touch pad will.
    private var swipePad: some View {
        RoundedRectangle(cornerRadius: AppSpacing.radiusM)
            .fill(.fill.tertiary)
            .frame(height: 260)
            .overlay { Text("Swipe up / down here to strum").foregroundStyle(.secondary) }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { model.swipeChanged(translation: $0.translation.height, eventDate: $0.time) }
                    .onEnded { _ in model.swipeEnded() }
            )
    }

    private var stateText: String {
        switch model.state {
        case .unpaired: "Not paired"
        case .pairing: "Pairing…"
        case .searching: "Searching…"
        case .reconnecting: "Reconnecting…"
        case let .connected(latencyMs): "Connected, \(String(format: "%.1f", latencyMs)) ms"
        }
    }
}

#Preview("Link test - iPad") {
    ControllerLinkDebugView(model: ControllerLinkDebugModel(role: .host, deviceName: "Preview iPad"))
}

#Preview("Link test - iPhone") {
    ControllerLinkDebugView(model: ControllerLinkDebugModel(role: .controller, deviceName: "Preview iPhone"))
}
#endif
