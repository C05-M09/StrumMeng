import SwiftUI

/// What the iPhone opens to: pairing until connected, then the strum pad.
struct CompanionRootView: View {
    @State private var viewModel: CompanionViewModel

    init(viewModel: CompanionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .connected, .reconnecting:
                CompanionTouchpadView(viewModel: viewModel)
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
