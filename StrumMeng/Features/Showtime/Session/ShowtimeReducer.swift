/// No services, clocks or persistence: illegal events always leave state unchanged.
func reduce(_ state: ShowtimeState, _ event: ShowtimeEvent) -> ShowtimeState {
    switch (state, event) {
    case (.intro, .next): return .listening(0)
    case (.listening, .selectPattern(let index)) where index >= 0: return .listening(0)
    case (.ready, .selectPattern(let index)) where index >= 0: return .listening(0)
    case (.listening, .previewStep(let step)): return .listening(max(0, step))
    case (.listening, .previewFinished): return .ready
    // Completion queued just before Pause must still unlock Ready after Resume.
    case (.paused(.listening, let reason), .previewFinished): return .paused(.ready, reason)
    case (.ready, .ready): return .countIn(3)
    case (.countIn, .countdown(let number)) where (1...3).contains(number): return .countIn(number)
    case (.countIn, .firstBeat): return .playing
    case (.listening(let step), .pause(let reason)): return .paused(.listening(step), reason)
    case (.ready, .pause(let reason)): return .paused(.ready, reason)
    case (.countIn(let number), .pause(let reason)): return .paused(.countIn(number), reason)
    case (.playing, .pause(let reason)): return .paused(.playing, reason)
    case (.paused(let stage, _), .pause(.connection)): return .paused(stage, .connection)
    case (.paused(.listening(let step), _), .resume): return .listening(step)
    case (.paused(.ready, _), .resume): return .ready
    case (.paused(.countIn, _), .resume), (.paused(.playing, _), .resume): return .countIn(3)
    case (.paused(.listening, _), .restart), (.paused(.ready, _), .restart),
         (.finished, .restart): return .listening(0)
    case (.paused(.countIn, _), .restart), (.paused(.playing, _), .restart): return .countIn(3)
    case (.playing, .completed(let result)): return .finished(result)
    case (.exited, _): return .exited
    case (_, .back): return .exited
    default: return state
    }
}
