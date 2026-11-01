import Foundation

func reduce(_ state: CompanionState, _ event: CompanionEvent) -> CompanionState {
    switch (state, event) {
    case let (.enteringCode(code), .typeDigit(digit)):
        guard (0...9).contains(digit) else { return state }
        let typed = code + String(digit)
        return typed.count == PairCode.length ? .connecting(typed) : .enteringCode(typed)

    case let (.enteringCode(code), .deleteDigit):
        return .enteringCode(String(code.dropLast()))

    case (.connecting, .linkConnected):
        return .connected

    case (.connecting, .disconnect), (.connected, .disconnect):
        return .enteringCode("")

    default:
        return state
    }
}
