#if DEBUG
import Foundation
import Observation

/// DEBUG-only harness for trying the Bonjour link on a real iPad + iPhone before the connect
/// screens exist (US 10). It lives in App because only the composition layer may build concrete
/// services. Delete it once the Controller feature screens replace it.
@MainActor
@Observable
final class ControllerLinkDebugModel {
    private static let hostCodeKey = "debug.controllerLink.hostPairCode"
    private static let enteredCodeKey = "debug.controllerLink.enteredPairCode"
    private static let logLimit = 30

    let role: DeviceRole
    let hostPairCode: PairCode?
    private(set) var state: ControllerConnectionState = .unpaired
    private(set) var sessionActive = false
    private(set) var log: [String] = []
    var enteredCode: String

    private let link: BonjourControllerLink?
    private let client: BonjourControllerClient?
    private var tasks: [Task<Void, Never>] = []

    init(role: DeviceRole, deviceName: String) {
        self.role = role
        let defaults = UserDefaults.standard
        enteredCode = defaults.string(forKey: Self.enteredCodeKey) ?? ""
        switch role {
        case .host:
            let code = defaults.string(forKey: Self.hostCodeKey).flatMap(PairCode.init) ?? PairCode.random()
            defaults.set(code.value, forKey: Self.hostCodeKey)
            hostPairCode = code
            link = BonjourControllerLink(pairCode: code)
            client = nil
        case .controller:
            hostPairCode = nil
            link = nil
            client = BonjourControllerClient(deviceName: deviceName)
        }
    }

    func appear() {
        guard tasks.isEmpty else { return }
        if let link {
            tasks.append(Task { for await state in link.connectionStates { self.state = state } })
            tasks.append(Task {
                for await strum in link.strums {
                    // How long after the touch the strum reached the UI: what US 6 latency testing needs.
                    let delayMs = (HostClock.now() - strum.time) * 1000
                    self.append("\(strum.direction) strum, \(String(format: "%.1f", delayMs)) ms after touch")
                }
            })
            tasks.append(Task {
                do { try await link.start() } catch { self.append("Could not start: \(error)") }
            })
        }
        if let client {
            tasks.append(Task { for await state in client.connectionStates { self.state = state } })
            tasks.append(Task { for await active in client.sessionActive { self.sessionActive = active } })
            if let code = PairCode(enteredCode) { connect(code) }
        }
    }

    func disappear() {
        tasks.forEach { $0.cancel() }
        tasks = []
        let link = link
        let client = client
        Task {
            await link?.stop()
            await client?.disconnect()
        }
    }

    // MARK: iPad

    func toggleSession() {
        guard let link else { return }
        sessionActive.toggle()
        let active = sessionActive
        append(active ? "Session started" : "Session stopped")
        Task { await link.setSessionActive(active) }
    }

    // MARK: iPhone

    func connectTapped() {
        guard let code = PairCode(enteredCode) else {
            append("The code must be 6 digits")
            return
        }
        UserDefaults.standard.set(code.value, forKey: Self.enteredCodeKey)
        connect(code)
    }

    func strum(_ direction: StrumDirection) {
        guard let client else { return }
        let touchTime = HostClock.now()
        append(sessionActive ? "Sent \(direction)" : "Not sent: no session on the iPad")
        Task { await client.send(direction, touchTime: touchTime) }
    }

    private func connect(_ code: PairCode) {
        guard let client else { return }
        append("Looking for iPad with code \(code)")
        Task { await client.connect(pairCode: code) }
    }

    private func append(_ line: String) {
        log.insert(line, at: 0)
        if log.count > Self.logLimit { log.removeLast() }
    }
}
#endif
