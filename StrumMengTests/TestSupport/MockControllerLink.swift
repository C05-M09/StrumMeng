import Foundation
@testable import StrumMeng

/// Scripted controller. Tests push strums and connection changes; commands are recorded.
final class MockControllerLink: ControllerLink {
    private(set) var startCount = 0
    private(set) var refreshCount = 0
    private(set) var stopCount = 0
    private(set) var sessionActiveCalls: [Bool] = []

    let pairCode: PairCode

    private let strumChannel = AsyncStream.makeStream(of: StrumEvent.self)
    private let stateChannel = AsyncStream.makeStream(of: ControllerConnectionState.self)

    init(pairCode: PairCode = PairCode("123456") ?? .random()) {
        self.pairCode = pairCode
    }

    var strums: AsyncStream<StrumEvent> { strumChannel.stream }
    var connectionStates: AsyncStream<ControllerConnectionState> { stateChannel.stream }

    func start() async throws { startCount += 1 }
    func refreshIfNeeded() async throws { refreshCount += 1 }
    func setSessionActive(_ active: Bool) async { sessionActiveCalls.append(active) }
    func stop() async { stopCount += 1 }

    func emit(_ strum: StrumEvent) {
        strumChannel.continuation.yield(strum)
    }

    func emit(_ state: ControllerConnectionState) {
        stateChannel.continuation.yield(state)
    }
}
