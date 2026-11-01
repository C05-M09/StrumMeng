import Foundation
@testable import StrumMeng

final class MockPairCodeStore: PairCodeStore {
    var hostCode: PairCode
    var enteredPairCode: PairCode?

    init(hostCode: PairCode = PairCode.random(), enteredPairCode: PairCode? = nil) {
        self.hostCode = hostCode
        self.enteredPairCode = enteredPairCode
    }

    func hostPairCode() -> PairCode { hostCode }

    func setEnteredPairCode(_ code: PairCode?) {
        enteredPairCode = code
    }
}
