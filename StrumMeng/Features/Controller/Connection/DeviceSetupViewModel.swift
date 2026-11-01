import Foundation
import Observation

@MainActor
@Observable
final class DeviceSetupViewModel {
    /// Shown until the screen gets the real code from the link.
    static let dummyPairCode = "482913"

    private(set) var state: DeviceSetupState
    let pairCode: String

    private let onClose: () -> Void

    init(
        state: DeviceSetupState = .searching,
        pairCode: String = DeviceSetupViewModel.dummyPairCode,
        onClose: @escaping () -> Void
    ) {
        self.state = state
        self.pairCode = pairCode
        self.onClose = onClose
    }

    /// Done only works once the iPhone is connected.
    var canFinish: Bool { state == .connected }

    func send(_ event: DeviceSetupEvent) {
        state = reduce(state, event)

        switch event {
        case .simulateNextState:
            break
        case .tapDone:
            if canFinish { onClose() }
        case .tapBack:
            onClose()
        }
    }
}
