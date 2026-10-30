import Foundation
import Network

/// iPhone side of the controller link over regular Wi-Fi. Browses for the iPad's Bonjour service,
/// connects with the pair code, pings to keep the clocks in sync and sends strums.
///
/// Same structure as BonjourControllerLink: the actor runs on the Network callback queue, and
/// message meaning lives in ClientMessageHandler.
actor BonjourControllerClient: ControllerClient {
    /// A wrong pair code makes the DTLS handshake hang rather than fail, so give up on that iPad
    /// after this long and try the next one.
    private static let handshakeTimeout: Duration = .seconds(4)
    private static let retryDelay: Duration = .milliseconds(500)

    private let deviceName: String
    private nonisolated let queue = DispatchSerialQueue(label: "StrumMeng.BonjourControllerClient", qos: .userInteractive)
    private nonisolated let stateBroadcast = AsyncBroadcast<ControllerConnectionState>(latest: .unpaired)
    private nonisolated let sessionBroadcast = AsyncBroadcast<Bool>(latest: false)

    private var pairCode: PairCode?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var isReady = false
    /// iPads that rejected our code (someone else's iPad nearby). Cleared when we run out.
    private var rejected: Set<NWEndpoint> = []
    private var hasEverConnected = false
    private var handler = ClientMessageHandler()
    private var pingTask: Task<Void, Never>?
    private var handshakeTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    nonisolated var connectionStates: AsyncStream<ControllerConnectionState> { stateBroadcast.stream() }
    nonisolated var sessionActive: AsyncStream<Bool> { sessionBroadcast.stream() }

    /// - Parameter deviceName: shown on the iPad. Passed in because reading it needs UIKit.
    init(deviceName: String) {
        self.deviceName = deviceName
    }

    func connect(pairCode: PairCode) async {
        await disconnect()
        self.pairCode = pairCode
        startBrowsing()
        stateBroadcast.yield(.searching)
    }

    func send(_ direction: StrumDirection, touchTime: TimeInterval) async {
        guard isReady, let connection,
              let message = handler.strumMessage(id: UUID(), direction: direction, touchTime: touchTime),
              let data = try? message.encoded() else { return }
        connection.send(content: data, completion: .idempotent)
        // Copies spread out a little, because Wi-Fi tends to lose packets in bursts. The iPad
        // keeps only the first copy that arrives.
        for delayMs in [3, 8].prefix(ClientMessageHandler.strumCopies - 1) {
            queue.asyncAfter(deadline: .now() + .milliseconds(delayMs)) {
                connection.send(content: data, completion: .idempotent)
            }
        }
    }

    func disconnect() async {
        stopBrowsing()
        dropConnection()
        retryTask?.cancel()
        retryTask = nil
        pairCode = nil
        rejected = []
        hasEverConnected = false
        stateBroadcast.yield(.unpaired)
    }

    // MARK: - Finding and connecting

    /// Browsing runs only while there is no connection: an active browser keeps scanning the
    /// network, which costs radio time the strums need.
    private func startBrowsing() {
        guard browser == nil else { return }
        let browser = NWBrowser(for: .bonjour(type: BonjourParameters.serviceType, domain: nil),
                                using: BonjourParameters.browsing())
        browser.browseResultsChangedHandler = { [weak self] _, _ in
            self?.assumeIsolated { $0.connectIfNeeded() }
        }
        browser.start(queue: queue)
        self.browser = browser
    }

    private func stopBrowsing() {
        browser?.cancel()
        browser = nil
    }

    private func connectIfNeeded() {
        guard connection == nil, let pairCode, let results = browser?.browseResults, !results.isEmpty else { return }
        guard let ipad = results.first(where: { !rejected.contains($0.endpoint) }) else {
            // Every iPad nearby refused the code. Maybe the code was just changed: start over soon.
            rejected = []
            scheduleRetry()
            return
        }
        let candidate = NWConnection(to: ipad.endpoint, using: BonjourParameters.make(pairCode: pairCode))
        connection = candidate
        if !hasEverConnected { stateBroadcast.yield(.pairing) }
        candidate.stateUpdateHandler = { [weak self, weak candidate] state in
            guard let candidate else { return }
            self?.assumeIsolated { $0.connectionChanged(candidate, endpoint: ipad.endpoint, state) }
        }
        candidate.start(queue: queue)
        handshakeTask = Task { [weak self] in
            try? await Task.sleep(for: Self.handshakeTimeout)
            guard !Task.isCancelled else { return }
            await self?.handshakeTimedOut(candidate, endpoint: ipad.endpoint)
        }
    }

    private func connectionChanged(_ changed: NWConnection, endpoint: NWEndpoint, _ state: NWConnection.State) {
        guard changed === connection else { return }
        switch state {
        case .ready:
            handshakeTask?.cancel()
            stopBrowsing()
            isReady = true
            hasEverConnected = true
            handler.connectionOpened(at: HostClock.now())
            sessionBroadcast.yield(false)
            receiveNext(on: changed)
            send(.hello(deviceName: deviceName))
            startPinging()
        case let .waiting(error), let .failed(error):
            if case .tls = error { rejected.insert(endpoint) }
            connectionLost()
        case .cancelled:
            connectionLost()
        default:
            break
        }
    }

    private func handshakeTimedOut(_ candidate: NWConnection, endpoint: NWEndpoint) {
        guard candidate === connection, !isReady else { return }
        rejected.insert(endpoint)
        connectionLost()
    }

    private func connectionLost() {
        dropConnection()
        stateBroadcast.yield(hasEverConnected ? .reconnecting : .searching)
        // Browsing stopped once connected; the iPad may also have a new address now.
        startBrowsing()
        scheduleRetry()
    }

    private func dropConnection() {
        pingTask?.cancel()
        pingTask = nil
        handshakeTask?.cancel()
        handshakeTask = nil
        connection?.cancel()
        connection = nil
        isReady = false
        if sessionBroadcast.latest == true { sessionBroadcast.yield(false) }
    }

    private func scheduleRetry() {
        retryTask?.cancel()
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: Self.retryDelay)
            guard !Task.isCancelled else { return }
            await self?.connectIfNeeded()
        }
    }

    // MARK: - Messages

    /// Pings keep the clock offset fresh and double as the liveness check in both directions.
    private func startPinging() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            var count = 0
            while !Task.isCancelled {
                count += 1
                guard let self, let delay = await self.pingAndCheckLiveness(count: count) else { return }
                try? await Task.sleep(for: delay)
            }
        }
    }

    /// Returns how long to wait before the next ping, or nil once the iPad has gone quiet and the
    /// connection was dropped.
    private func pingAndCheckLiveness(count: Int) -> Duration? {
        let now = HostClock.now()
        guard handler.isAlive(now: now) else {
            connectionLost()
            return nil
        }
        send(handler.pingMessage(sentAt: now))
        return ClientMessageHandler.pingDelay(afterPing: count, sessionActive: handler.sessionActive)
    }

    private func receiveNext(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            let arrival = HostClock.now()
            self?.assumeIsolated { client in
                guard connection === client.connection else { return }
                if let data { client.handle(data, arrivedAt: arrival) }
                if error == nil { client.receiveNext(on: connection) }
            }
        }
    }

    private func handle(_ data: Data, arrivedAt arrival: TimeInterval) {
        guard let message = try? ControllerMessage(data: data) else { return }
        let wasActive = handler.sessionActive
        handler.receive(message, arrivedAt: arrival)
        if handler.sessionActive != wasActive {
            sessionBroadcast.yield(handler.sessionActive)
            // Switch to the fast play rate now rather than after the current (up to 1 s) wait.
            if handler.sessionActive { startPinging() }
        }
        if case .pong = message, let latencyMs = handler.clock.latencyMs {
            stateBroadcast.yield(.connected(latencyMs: latencyMs))
        }
    }

    private func send(_ message: ControllerMessage) {
        guard let connection, let data = try? message.encoded() else { return }
        connection.send(content: data, completion: .idempotent)
    }
}
