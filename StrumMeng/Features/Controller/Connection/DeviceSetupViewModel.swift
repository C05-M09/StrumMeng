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

    /// Refresh is offered when the iPad is stuck: it cannot reach the iPhone by itself.
    var canRefresh: Bool {
        state == .reconnecting || state == .failed
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

    /// Stop and start the link: a fresh listener and Bonjour advertisement, and the iPad back to
    /// showing the code. A saved iPhone reconnects by itself. Only from this screen, never during a
    /// session (the link is meant to stay up, CLAUDE.md §7).
    private func restartLink() {
        startTask?.cancel()
        startTask = Task { [weak self, link] in
            await link.stop()
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
        let couldRefresh = canRefresh
        state = reduce(state, event)

        switch event {
        case .linkStateChanged, .linkFailed:
            break
        case .tapRefresh:
            guard couldRefresh else { return }
            restartLink()
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
