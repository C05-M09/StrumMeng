enum ListenEvent: Equatable {
    case next, showGuidance, pause, resume, restart, ready, back
    case progress(step: Int, completed: Bool)
    case instructionsNext, retryHistory
    case historyChecked(hasRecords: Bool)
    case historyCheckFailed(String)
    case failed(String)
    /// The iPhone dropped. Only matters while the example plays or is paused.
    case controllerDisconnected
    /// Ready after a full loop, but with no iPhone to play on.
    case readyWithoutController
}
