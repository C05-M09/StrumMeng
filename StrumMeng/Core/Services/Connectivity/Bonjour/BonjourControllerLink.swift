import Foundation
import Network

/// iPad side of the controller link over regular Wi-Fi (the fallback to Wi-Fi Aware). Advertises a
/// Bonjour service and accepts the iPhone that knows the pair code.
///
/// The actor runs on the same serial queue the Network callbacks use, so callbacks enter it with
/// assumeIsolated and connection state needs no locks. Message meaning lives in
/// HostMessageHandler; this type only moves bytes, which is why it is verified on real devices
/// rather than unit-tested.
actor BonjourControllerLink: ControllerLink {
    /// Polling interval for the liveness check. Not beat timing, so a sleeping task is fine.
    private static let livenessCheckInterval: Duration = .milliseconds(500)
    /// Wait before replacing a listener that stopped, so one that keeps failing does not spin.
    private static let listenerRestartDelay: Duration = .seconds(1)

    nonisolated let pairCode: PairCode

    private nonisolated let queue = DispatchSerialQueue(label: "StrumMeng.BonjourControllerLink", qos: .userInteractive)
    private nonisolated let strumBroadcast = AsyncBroadcast<StrumEvent>()
    private nonisolated let stateBroadcast = AsyncBroadcast<ControllerConnectionState>(latest: .unpaired)

    private var listener: NWListener?
    /// The controller in use. Only one iPhone at a time; a newer one that completes the handshake
    /// replaces it (for example the same iPhone reconnecting).
    private var connection: NWConnection?
    private var handler = HostMessageHandler()
    private var hasEverConnected = false
    private var livenessTask: Task<Void, Never>?
    private var listenerRestartTask: Task<Void, Never>?

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }

    nonisolated var strums: AsyncStream<StrumEvent> { strumBroadcast.stream() }
    nonisolated var connectionStates: AsyncStream<ControllerConnectionState> { stateBroadcast.stream() }

    init(pairCode: PairCode) {
        self.pairCode = pairCode
    }

    func start() async throws {
        guard listener == nil else { return }
        try startListener()
        if connection == nil { stateBroadcast.yield(.searching) }
        livenessTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.livenessCheckInterval)
                await self?.checkLiveness()
            }
        }
    }

    /// Bonjour has no publish time limit, but iOS can stop the listener or its advertisement while
    /// the app is away, and nothing reports it. So while no iPhone is connected, open a fresh
    /// listener. A connected iPhone is left alone (its connection does not depend on the listener).
    func refreshIfNeeded() async throws {
        guard livenessTask != nil, connection == nil else { return }
        restartListener()
    }

    func setSessionActive(_ active: Bool) async {
        handler.sessionActive = active
        sendWithCopies(active ? .startSession : .stopSession)
    }

    func stop() async {
        livenessTask?.cancel()
        livenessTask = nil
        listenerRestartTask?.cancel()
        listenerRestartTask = nil
        listener?.cancel()
        listener = nil
        connection?.cancel()
        connection = nil
        hasEverConnected = false
        stateBroadcast.yield(.unpaired)
    }

    // MARK: - Listener

    private func startListener() throws {
        let listener = try NWListener(using: BonjourParameters.make(pairCode: pairCode))
        // No name given: Bonjour uses the device name, which is what the iPhone shows.
        listener.service = NWListener.Service(type: BonjourParameters.serviceType)
        listener.newConnectionHandler = { [weak self] connection in
            self?.assumeIsolated { $0.accept(connection) }
        }
        listener.stateUpdateHandler = { [weak self, weak listener] state in
            guard let listener else { return }
            self?.assumeIsolated { $0.listenerChanged(listener, state) }
        }
        listener.start(queue: queue)
        self.listener = listener
    }

    private func listenerChanged(_ changed: NWListener, _ state: NWListener.State) {
        // A listener this link replaced reports .cancelled too; only the current one matters.
        guard changed === listener else { return }
        switch state {
        case .failed, .cancelled:
            // A network change, or iOS stopping it while the app was away. Without a listener the
            // iPhone can never reconnect, so open a fresh one; the current connection may survive.
            listener = nil
            changed.cancel()
            listenerRestartTask?.cancel()
            listenerRestartTask = Task { [weak self] in
                try? await Task.sleep(for: Self.listenerRestartDelay)
                guard !Task.isCancelled else { return }
                await self?.restartListener()
            }
        default:
            break
        }
    }

    /// Replaces the listener with a fresh one (new Bonjour advertisement). The state is unchanged:
    /// the iPad still waits for the same iPhone. If it cannot start, the next refresh tries again.
    private func restartListener() {
        listenerRestartTask?.cancel()
        listenerRestartTask = nil
        let old = listener
        listener = nil
        old?.cancel()
        try? startListener()
    }

    // MARK: - Connection

    /// A new iPhone is knocking. It only replaces the current controller once its DTLS handshake
    /// succeeds, so a device with the wrong code cannot kick the paired iPhone off.
    private func accept(_ candidate: NWConnection) {
        candidate.stateUpdateHandler = { [weak self, weak candidate] state in
            guard let candidate else { return }
            self?.assumeIsolated { $0.connectionChanged(candidate, state) }
        }
        candidate.start(queue: queue)
    }

    private func connectionChanged(_ changed: NWConnection, _ state: NWConnection.State) {
        switch state {
        case .ready:
            if let old = connection, old !== changed { old.cancel() }
            connection = changed
            hasEverConnected = true
            handler.connectionOpened(at: HostClock.now())
            receiveNext(on: changed)
        case .failed, .cancelled:
            changed.cancel()
            guard changed === connection else { return }
            connectionLost()
        default:
            break
        }
    }

    private func connectionLost() {
        connection?.cancel()
        connection = nil
        stateBroadcast.yield(hasEverConnected ? .reconnecting : .searching)
    }

    private func checkLiveness() {
        guard connection != nil, !handler.isAlive(now: HostClock.now()) else { return }
        connectionLost()
    }

    // MARK: - Messages

    private func receiveNext(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            // Stamp the arrival before anything else; it is the fallback strum time.
            let arrival = HostClock.now()
            self?.assumeIsolated { link in
                guard connection === link.connection else { return }
                if let data { link.handle(data, arrivedAt: arrival) }
                if error == nil { link.receiveNext(on: connection) }
            }
        }
    }

    private func handle(_ data: Data, arrivedAt arrival: TimeInterval) {
        guard let message = try? ControllerMessage(data: data) else { return }
        switch handler.receive(message, arrivedAt: arrival) {
        case let .reply(reply):
            send(reply)
        case let .strum(strum):
            strumBroadcast.yield(strum)
        case .ignore:
            break
        }
        if case .ping = message {
            stateBroadcast.yield(.connected(latencyMs: handler.latencyMs ?? 0))
        }
    }

    private func send(_ message: ControllerMessage) {
        guard let connection, let data = try? message.encoded() else { return }
        connection.send(content: data, completion: .idempotent)
    }

    /// Start/stop must not get lost, so they are sent like strums: several copies, spread out a
    /// little because Wi-Fi tends to lose packets in bursts. The pong repeats the state anyway.
    private func sendWithCopies(_ message: ControllerMessage) {
        guard let connection, let data = try? message.encoded() else { return }
        connection.send(content: data, completion: .idempotent)
        for delayMs in [3, 8] {
            queue.asyncAfter(deadline: .now() + .milliseconds(delayMs)) {
                connection.send(content: data, completion: .idempotent)
            }
        }
    }
}
