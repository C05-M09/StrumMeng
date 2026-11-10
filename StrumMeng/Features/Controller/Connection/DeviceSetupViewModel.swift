import Foundation
import Observation

@MainActor
@Observable
final class DeviceSetupViewModel {
    private(set) var state: DeviceSetupState

    @ObservationIgnored private let link: any ControllerLink
    @ObservationIgnored private let onClose: () -> Void
    @ObservationIgnored private let onPairedDone: () -> Void
    @ObservationIgnored private var linkTask: Task<Void, Never>?
    @ObservationIgnored private var startTask: Task<Void, Never>?

    init(
        link: any ControllerLink,
        state: DeviceSetupState = .searching,
        onClose: @escaping () -> Void,
        onPairedDone: @escaping () -> Void = {}
    ) {
        self.link = link
        self.state = state
        self.onClose = onClose
        self.onPairedDone = onPairedDone
    }

    var pairCode: String { link.pairCode.value }

    /// Done only works once the iPhone is connected.
    var canFinish: Bool {
        if case .connected = state { return true }
        return false
    }

    /// Follows the link while the screen is open. The link itself stays up after the screen closes:
    /// it lives for the whole app session and start() does nothing if it is already running.
    func appear() {
        guard linkTask == nil else { return }
        linkTask = Task { [weak self, states = link.connectionStates] in
            for await linkState in states {
                self?.send(.linkStateChanged(linkState))
            }
        }
        startTask = Task { [weak self, link] in
            do {
                try await link.start()
            } catch {
                self?.send(.linkFailed)
            }
        }
    }

    func disappear() {
        linkTask?.cancel()
        linkTask = nil
        startTask?.cancel()
        startTask = nil
    }

    func send(_ event: DeviceSetupEvent) {
        state = reduce(state, event)

        switch event {
        case .linkStateChanged, .linkFailed:
            break
        case .tapDone:
            if canFinish {
                onPairedDone()
                onClose()
            }
        case .tapBack:
            onClose()
        }
    }
}
