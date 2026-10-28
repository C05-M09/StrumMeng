import Foundation

/// Pure state transition for a practice session. Side effects belong to PlayViewModel.
/// Any (state, event) pair not listed is illegal and leaves the state unchanged.
func reduce(_ state: PracticeState, _ event: PracticeEvent) -> PracticeState {
    switch (state, event) {
    case (.idle, .startListening):
        return .listening
    case (.listening, .replayExample):
        return .listening
    case (.listening, .tapNext):
        return .ready
    case (.ready, .tapReady):
        return .countIn(3)

    case (.countIn(let n), .countInTick):
        return .countIn(max(1, n - 1))
    case (.countIn, .countInDone):
        return .playing

    case (.countIn, .tapPause), (.countIn, .controllerDisconnected), (.countIn, .appMovedToBackground),
         (.playing, .tapPause), (.playing, .controllerDisconnected), (.playing, .appMovedToBackground):
        return .paused
    case (.playing, .sessionEnded(let result)):
        return .finished(result)

    // Resume re-counts before continuing; Restart starts a fresh session. Both count in first.
    case (.paused, .tapResume), (.paused, .tapRestart):
        return .countIn(3)

    // Retry from the result goes back to Ready (the recommendation popup belongs to Summary).
    case (.finished, .tapRestart):
        return .ready

    case (.listening, .tapBackToMenu), (.ready, .tapBackToMenu), (.paused, .tapBackToMenu),
         (.finished, .tapBackToMenu):
        return .idle

    default:
        return state
    }
}
