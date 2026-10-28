import Foundation
@testable import StrumMeng

/// Scripted iPhone-side link. Tests push connection and session changes; sends are recorded.
final class MockControllerClient: ControllerClient {
    private(set) var connectedCodes: [PairCode] = []
    private(set) var sentStrums: [(direction: StrumDirection, touchTime: TimeInterval)] = []
    private(set) var disconnectCount = 0

    private let stateChannel = AsyncStream.makeStream(of: ControllerConnectionState.self)
    private let sessionChannel = AsyncStream.makeStream(of: Bool.self)

    var connectionStates: AsyncStream<ControllerConnectionState> { stateChannel.stream }
    var sessionActive: AsyncStream<Bool> { sessionChannel.stream }

    func connect(pairCode: PairCode) async { connectedCodes.append(pairCode) }
    func send(_ direction: StrumDirection, touchTime: TimeInterval) async { sentStrums.append((direction, touchTime)) }
    func disconnect() async { disconnectCount += 1 }

    func emit(_ state: ControllerConnectionState) {
        stateChannel.continuation.yield(state)
    }

    func emitSessionActive(_ active: Bool) {
        sessionChannel.continuation.yield(active)
    }
}
