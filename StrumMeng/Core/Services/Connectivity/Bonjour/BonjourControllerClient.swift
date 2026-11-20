import Foundation
import Network

/// iPhone side of the controller link over regular Wi-Fi. Browses for the iPad's Bonjour service,
/// connects with the pair code, pings to keep the clocks in sync and sends strums.
///
/// Same structure as BonjourControllerLink: the actor runs on the Network callback queue, and
/// message meaning lives in ClientMessageHandler.
actor BonjourControllerClient: ControllerClient {
    /// A wrong pair code makes the DTLS handshake hang rather than fail, so give up on that iPad
    /// after this long and skip it on the next round.
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
    /// The iPad in use, set once its handshake succeeded.
    private var connection: NWConnection?
    /// Handshakes still running, one per iPad found (see connectIfNeeded).
    private var candidates: [NWEndpoint: Candidate] = [:]
    private var isReady = false
    /// iPads that rejected our code (someone else's iPad nearby). Cleared when we run out.
    private var rejected: Set<NWEndpoint> = []
    private var hasEverConnected = false
    /// Between leaveForBackground and returnFromBackground: no pings, so the iPad keeps the
    /// controller paused even if the connection survives.
    private var isAway = false
    private var handler = ClientMessageHandler()
    private var pingTask: Task<Void, Never>?
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
        sendCopies(data, on: connection)
    }

    func unpair() async {
        if isReady, let connection, let data = try? ControllerMessage.goodbye.encoded() {
            // If every copy is lost the iPad only sees the pings stop, and waits as Reconnecting
            // instead of showing its code for the next iPhone.
            sendCopies(data, on: connection)
            // Give the copies a moment to leave before the connection is cancelled.
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
        // If all copies are lost the iPad notices when the pings stop.
        sendCopies(data, on: connection)
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

    /// Knocks on every iPad found that has not refused the code yet, all at once. A wrong code
    /// only fails after the handshake timeout, so trying them one by one took that long per iPad:
    /// with many StrumMeng iPads on one network (a classroom), the right one was often not reached
    /// before the iPhone gave up. The first handshake that succeeds wins; the rest are cancelled.
    private func connectIfNeeded() {
        guard connection == nil, let pairCode, let results = browser?.browseResults, !results.isEmpty else { return }
        let untried = results.map(\.endpoint).filter { !rejected.contains($0) && candidates[$0] == nil }
        guard !untried.isEmpty else {
            // Every iPad nearby refused the code. Maybe the code was just changed: start over soon.
            if candidates.isEmpty {
                rejected = []
                scheduleRetry()
            }
            return
        }
        if candidates.isEmpty, !hasEverConnected { stateBroadcast.yield(.pairing) }
        for endpoint in untried {
            startCandidate(to: endpoint, pairCode: pairCode)
        }
    }

    private func startCandidate(to endpoint: NWEndpoint, pairCode: PairCode) {
        let candidate = NWConnection(to: endpoint, using: BonjourParameters.make(pairCode: pairCode))
        candidate.stateUpdateHandler = { [weak self, weak candidate] state in
            guard let candidate else { return }
            self?.assumeIsolated { $0.connectionChanged(candidate, endpoint: endpoint, state) }
        }
        let timeout = Task { [weak self] in
            try? await Task.sleep(for: Self.handshakeTimeout)
            guard !Task.isCancelled else { return }
            // A wrong code makes the handshake hang rather than fail.
            await self?.candidateFailed(candidate, endpoint: endpoint, wrongCode: true)
        }
        candidates[endpoint] = Candidate(connection: candidate, timeout: timeout)
        candidate.start(queue: queue)
    }

    private func connectionChanged(_ changed: NWConnection, endpoint: NWEndpoint, _ state: NWConnection.State) {
        if changed === connection {
            switch state {
            case .waiting, .failed, .cancelled:
                connectionLost(hostLeft: handler.sessionActive)
            default:
                break
            }
            return
        }
        guard candidates[endpoint]?.connection === changed else { return }
        switch state {
        case .ready:
            adopt(changed, endpoint: endpoint)
        case let .waiting(error), let .failed(error):
            var wrongCode = false
            if case .tls = error { wrongCode = true }
            candidateFailed(changed, endpoint: endpoint, wrongCode: wrongCode)
        case .cancelled:
            candidateFailed(changed, endpoint: endpoint, wrongCode: false)
        default:
            break
        }
    }

    /// The iPad that knows the code. The other knocks are cancelled.
    private func adopt(_ ready: NWConnection, endpoint: NWEndpoint) {
        candidates[endpoint]?.timeout.cancel()
        candidates[endpoint] = nil
        cancelCandidates()
        stopBrowsing()
        connection = ready
        isReady = true
        hasEverConnected = true
        handler.connectionOpened(at: HostClock.now())
        sessionBroadcast.yield(false)
        receiveNext(on: ready)
        // Connected while the app was on its way out: say hello on return instead.
        if !isAway { greetAndPing() }
    }

    /// - Parameter wrongCode: that iPad refused the code, so it is skipped until every iPad has.
    private func candidateFailed(_ candidate: NWConnection, endpoint: NWEndpoint, wrongCode: Bool) {
        guard let entry = candidates[endpoint], entry.connection === candidate else { return }
        entry.timeout.cancel()
        candidates[endpoint] = nil
        candidate.cancel()
        if wrongCode { rejected.insert(endpoint) }
        guard candidates.isEmpty, connection == nil else { return }
        stateBroadcast.yield(hasEverConnected ? .reconnecting : .searching)
        scheduleRetry()
    }

    private func cancelCandidates() {
        let pending = candidates.values
        candidates = [:]
        for entry in pending {
            entry.timeout.cancel()
            entry.connection.cancel()
        }
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
        cancelCandidates()
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

    /// Messages that must not get lost go out several times, spread out a little because Wi-Fi
    /// tends to lose packets in bursts. The iPad acts on the first copy and ignores the rest.
    private func sendCopies(_ data: Data, on connection: NWConnection) {
        connection.send(content: data, completion: .idempotent)
        for delayMs in [3, 8].prefix(ClientMessageHandler.strumCopies - 1) {
            queue.asyncAfter(deadline: .now() + .milliseconds(delayMs)) {
                connection.send(content: data, completion: .idempotent)
            }
        }
    }

    private func send(_ message: ControllerMessage) {
        guard let connection, let data = try? message.encoded() else { return }
        connection.send(content: data, completion: .idempotent)
    }

    private struct Candidate {
        let connection: NWConnection
        let timeout: Task<Void, Never>
    }
}
