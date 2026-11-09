enum ListenEvent {
    case next, pause, resume, restart, ready, back
    case progress(step: Int, completed: Bool)
    case instructionsNext, retryHistory
    case historyChecked(hasRecords: Bool)
    case historyCheckFailed(String)
    case failed(String)
}
