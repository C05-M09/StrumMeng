import Foundation

func reduce(_ state: CompanionState, _ event: CompanionEvent) -> CompanionState {
    switch (state, event) {
    case let (.enteringCode(code), .typeDigit(digit)):
        guard (0...9).contains(digit) else { return state }
        let typed = code + String(digit)
        return typed.count == PairCode.length ? .connecting(typed) : .enteringCode(typed)

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

    case (.enteringCode, .clearCode), (.notFound, .clearCode), (.connecting, .clearCode):
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
