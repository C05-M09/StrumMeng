enum ShowtimeState: Equatable {
    case intro
    case listening(Int)
    case ready
    case countIn(Int)
    case playing
    case paused(ShowtimeStage, ShowtimePauseReason)
    case finished(SessionResult)
    case exited
}
