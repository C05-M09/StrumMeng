import Foundation

enum ListenState: Equatable {
    case information
    case listening(step: Int, completed: Bool)
    case paused(step: Int, completed: Bool)
    case checkingHistory(step: Int)
    case instructions(step: Int)
    case historyFailed(step: Int, message: String)
    case failed(String)
    case departed

    var step: Int {
        switch self {
        case let .listening(step, _), let .paused(step, _): step
        case let .checkingHistory(step), let .instructions(step), let .historyFailed(step, _): step
        default: 0
        }
    }

    var canProceed: Bool {
        switch self {
        case let .listening(_, completed): completed
        default: false
        }
    }
}
