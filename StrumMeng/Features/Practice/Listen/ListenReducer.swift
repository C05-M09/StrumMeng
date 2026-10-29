func reduce(_ state: ListenState, _ event: ListenEvent) -> ListenState {
    switch (state, event) {
    case (.listening(_, true), .ready), (_, .back):
        return .departed
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
