enum ShowtimeEvent {
    case next, previewStep(Int), ready
    /// A player completion is aggregated by the ViewModel; the reducer receives this after all are heard.
    case previewFinished
    case selectPattern(Int)
    case countdown(Int), firstBeat
    case pause(ShowtimePauseReason), resume, restart, back
    case completed(SessionResult)
}
