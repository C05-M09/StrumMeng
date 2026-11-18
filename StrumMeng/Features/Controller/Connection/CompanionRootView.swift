import SwiftUI

/// What the iPhone opens to: pairing until connected, then the strum pad.
struct CompanionRootView: View {
    @State private var viewModel: CompanionViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: CompanionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .connected, .reconnecting:
                CompanionTouchpadView(viewModel: viewModel)
            case .ipadDisconnected:
                ZStack {
                    CompanionTouchpadView(viewModel: viewModel)
                    IPadDisconnectedOverlay { viewModel.send(.disconnect) }
                }
            case .enteringCode, .connecting, .notFound:
                CompanionPairingView(viewModel: viewModel)
            }
        }
        // The keypad and Unpair click through the shared buttons; the view model decides when.
        .environment(\.playSoundEffect, SoundEffectAction { [viewModel] effect in
            viewModel.playSoundEffect(effect)
        })
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear { viewModel.appear() }
        .onDisappear { viewModel.stop() }
        // Only .background: Control Center or a banner (.inactive) is too brief to pause the iPad.
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: viewModel.appMovedToBackground()
            case .active: viewModel.appBecameActive()
            default: break
            }
        }
    }
}

#Preview("Entering code") {
    CompanionRootView(viewModel: .preview(state: .enteringCode("48")))
}

#Preview("Connecting") {
    CompanionRootView(viewModel: .preview(state: .connecting("482913")))
}

#Preview("iPad not found") {
    CompanionRootView(viewModel: .preview(state: .notFound("482913")))
}

#Preview("Connected") {
    CompanionRootView(viewModel: .preview(state: .connected))
}

#Preview("Reconnecting") {
    CompanionRootView(viewModel: .preview(state: .reconnecting))
}

#Preview("iPad disconnected") {
    CompanionRootView(viewModel: .preview(state: .ipadDisconnected))
}
