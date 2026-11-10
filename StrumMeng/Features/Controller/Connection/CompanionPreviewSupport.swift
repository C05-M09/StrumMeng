import Foundation

/// Stands in for the link and the saved codes in previews, which only show the state they are given.
/// Not DEBUG-only: #Preview blocks are compiled in Release builds too.
extension CompanionViewModel {
    static func preview(state: CompanionState) -> CompanionViewModel {
        CompanionViewModel(client: PreviewControllerClient(), pairCodes: PreviewPairCodeStore(), state: state)
    }
}

private struct PreviewControllerClient: ControllerClient {
    var connectionStates: AsyncStream<ControllerConnectionState> { AsyncStream { $0.finish() } }
    var sessionActive: AsyncStream<Bool> { AsyncStream { $0.finish() } }
    func connect(pairCode: PairCode) async {}
    func send(_ direction: StrumDirection, touchTime: TimeInterval) async {}
    func disconnect() async {}
}

private final class PreviewPairCodeStore: PairCodeStore {
    func hostPairCode() -> PairCode { PairCode.random() }
    var enteredPairCode: PairCode? { nil }
    func setEnteredPairCode(_ code: PairCode?) {}
}
