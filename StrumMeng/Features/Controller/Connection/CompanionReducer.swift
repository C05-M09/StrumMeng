import Foundation

func reduce(_ state: CompanionState, _ event: CompanionEvent) -> CompanionState {
    switch (state, event) {
    case let (.enteringCode(code), .typeDigit(digit)):
        guard (0...9).contains(digit), code.count < PairCode.length else { return state }
        return .enteringCode(code + String(digit))

    // A full code waits for the check key, so the player can see it before it is sent.
    case let (.enteringCode(code), .confirmCode), let (.notFound(code), .confirmCode):
        return code.count == PairCode.length ? .connecting(code) : state

    case let (.enteringCode(code), .deleteDigit):
        return .enteringCode(String(code.dropLast()))

    case let (.enteringCode, .resumePairing(code)):
        return .connecting(code)

    case let (.connecting(code), .connectionTimedOut):
        return .notFound(code)

    // Typing after a failed code starts a new one.
    case let (.notFound, .typeDigit(digit)):
        return reduce(.enteringCode(""), .typeDigit(digit))

    case (.notFound, .deleteDigit):
        return .enteringCode("")

    case (.connecting, .linkConnected), (.reconnecting, .linkConnected):
        return .connected

    case (.connected, .linkLost):
        return .reconnecting

    case (.connecting, .disconnect), (.connected, .disconnect), (.reconnecting, .disconnect):
        return .enteringCode("")

    default:
        return state
    }
}
