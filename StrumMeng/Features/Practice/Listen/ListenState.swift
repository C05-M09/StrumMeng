import Foundation

enum ListenState: Equatable {
    case information
    case listening(step: Int, completed: Bool)
    case paused(step: Int, completed: Bool)
    /// The iPhone is not connected: Ready was tapped without it, or it dropped while the example
    /// played. The example waits; Resume works once the iPhone is back.
    case disconnected(step: Int, completed: Bool)
    case checkingHistory(step: Int)
    case instructions(step: Int)
    case historyFailed(step: Int, message: String)
    case failed(String)
    case departed

    var step: Int {
        switch self {
        case let .listening(step, _), let .paused(step, _), let .disconnected(step, _): step
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

    var showsTrackingRing: Bool {
        switch self {
        case .listening, .paused: true
        default: false
        }
    }
}
