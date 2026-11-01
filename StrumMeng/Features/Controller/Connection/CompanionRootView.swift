import SwiftUI

/// What the iPhone opens to: pairing until connected, then the strum pad.
struct CompanionRootView: View {
    @State private var viewModel: CompanionViewModel

    init(viewModel: CompanionViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? CompanionViewModel())
    }

    var body: some View {
        Group {
            if viewModel.state == .connected {
                CompanionTouchpadView(viewModel: viewModel)
            } else {
                CompanionPairingView(viewModel: viewModel)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onDisappear { viewModel.stop() }
    }
}

#Preview("Entering code") {
    CompanionRootView(viewModel: CompanionViewModel(state: .enteringCode("48")))
}

#Preview("Connecting") {
    CompanionRootView(viewModel: CompanionViewModel(state: .connecting("482913")))
}

#Preview("Connected") {
    CompanionRootView(viewModel: CompanionViewModel(state: .connected))
}
