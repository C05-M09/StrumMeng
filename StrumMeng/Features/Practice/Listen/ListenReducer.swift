func reduce(_ state: ListenState, _ event: ListenEvent) -> ListenState {
    switch (state, event) {
    case (_, .back), (.instructions, .instructionsNext):
        return .departed
    case let (.listening(step, true), .ready), let (.historyFailed(step, _), .retryHistory):
        return .checkingHistory(step: step)
    case let (.checkingHistory(step), .historyChecked(hasRecords)):
        return hasRecords ? .departed : .instructions(step: step)
    case let (.checkingHistory(step), .historyCheckFailed(message)):
        return .historyFailed(step: step, message: message)
    case (.information, .next), (.paused, .restart), (.failed, .restart):
        return .listening(step: 0, completed: false)
    case let (.listening(_, finished), .progress(step, completed)):
        return .listening(step: step, completed: finished || completed)
    case let (.listening(step, completed), .pause):
        return .paused(step: step, completed: completed)
    case let (.paused(step, completed), .resume):
        return .listening(step: step, completed: completed)
    case (_, let .failed(message)):
        return .failed(message)
    default: return state
    }
}
