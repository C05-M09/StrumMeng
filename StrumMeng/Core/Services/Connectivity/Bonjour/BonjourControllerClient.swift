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
    private static let goodbyeFlushDelay: Duration = .milliseconds(30)

    private let deviceName: String
    private nonisolated let queue = DispatchSerialQueue(label: "StrumMeng.BonjourControllerClient", qos: .userInteractive)
    private nonisolated let stateBroadcast = AsyncBroadcast<ControllerConnectionState>(latest: .unpaired)
    private nonisolated let sessionBroadcast = AsyncBroadcast<Bool>(latest: false)
    private nonisolated let hostLeftBroadcast = AsyncBroadcast<Bool>(latest: false)

    private var pairCode: PairCode?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var isReady = false
    /// iPads that rejected our code (someone else's iPad nearby). Cleared when we run out.
    private var rejected: Set<NWEndpoint> = []
    private var hasEverConnected = false
    /// Between leaveForBackground and returnFromBackground: no pings, so the iPad keeps the
    /// controller paused even if the connection survives.
    private var isAway = false
    private var handler = ClientMessageHandler()
    private var pingTask: Task<Void, Never>?
    private var handshakeTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    nonisolated var connectionStates: AsyncStream<ControllerConnectionState> { stateBroadcast.stream() }
    nonisolated var sessionActive: AsyncStream<Bool> { sessionBroadcast.stream() }
    nonisolated var hostLeftSession: AsyncStream<Bool> { hostLeftBroadcast.stream() }

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

    func unpair() async {
        if isReady, let connection, let data = try? ControllerMessage.goodbye.encoded() {
            // Several copies, as UDP may lose one. If all are lost the iPad still notices when
            // the pings stop.
            for _ in 0..<ClientMessageHandler.strumCopies {
                connection.send(content: data, completion: .idempotent)
            }
            // Give the sends a moment to leave before the connection is cancelled.
            try? await Task.sleep(for: Self.goodbyeFlushDelay)
        }
        await disconnect()
    }

    func leaveForBackground() async {
        guard !isAway else { return }
        isAway = true
        pingTask?.cancel()
        pingTask = nil
        guard isReady, let connection, let data = try? ControllerMessage.away.encoded() else { return }
        // Several copies, as UDP may lose one. If all are lost the iPad notices when the pings stop.
        for _ in 0..<ClientMessageHandler.strumCopies {
            connection.send(content: data, completion: .idempotent)
        }
    }

    func returnFromBackground() async {
        guard isAway else { return }
        isAway = false
        guard isReady else { return }
        guard handler.isAlive(now: HostClock.now()) else {
            // Gone long enough for the iPad to drop us: find it again. This iPhone left, not the iPad.
            connectionLost(hostLeft: false)
            return
        }
        greetAndPing()
    }

    func disconnect() async {
        stopBrowsing()
        dropConnection()
        retryTask?.cancel()
        retryTask = nil
        pairCode = nil
        rejected = []
        hasEverConnected = false
        setHostLeft(false)
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
            // Connected while the app was on its way out: say hello on return instead.
            if !isAway { greetAndPing() }
        case let .waiting(error), let .failed(error):
            if case .tls = error { rejected.insert(endpoint) }
            connectionLost(hostLeft: handler.sessionActive)
        case .cancelled:
            connectionLost(hostLeft: handler.sessionActive)
        default:
            break
        }
    }

    private func handshakeTimedOut(_ candidate: NWConnection, endpoint: NWEndpoint) {
        guard candidate === connection, !isReady else { return }
        rejected.insert(endpoint)
        connectionLost(hostLeft: false)
    }

    /// - Parameter hostLeft: the iPad went quiet in the middle of a session (crashed, battery, or
    ///   left before its hostAway arrived), so the player is told the iPad is gone.
    private func connectionLost(hostLeft: Bool) {
        if hostLeft { setHostLeft(true) }
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

    /// The hello also tells the iPad that an away iPhone is back.
    private func greetAndPing() {
        send(.hello(deviceName: deviceName))
        startPinging()
    }

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
            connectionLost(hostLeft: handler.sessionActive)
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
        let wasHostAway = handler.isHostAway
        handler.receive(message, arrivedAt: arrival)
        if handler.isHostAway, !wasHostAway { setHostLeft(true) }
        if handler.sessionActive != wasActive {
            sessionBroadcast.yield(handler.sessionActive)
            // Switch to the fast play rate now rather than after the current (up to 1 s) wait.
            if handler.sessionActive { startPinging() }
        }
        // While the iPad is away only a pong to a newer ping says it is back.
        if case .pong = message, !handler.isHostAway, let latencyMs = handler.clock.latencyMs {
            setHostLeft(false)
            stateBroadcast.yield(.connected(latencyMs: latencyMs))
        }
    }

    private func setHostLeft(_ left: Bool) {
        if hostLeftBroadcast.latest != left { hostLeftBroadcast.yield(left) }
    }

    private func send(_ message: ControllerMessage) {
        guard let connection, let data = try? message.encoded() else { return }
        connection.send(content: data, completion: .idempotent)
    }
}
