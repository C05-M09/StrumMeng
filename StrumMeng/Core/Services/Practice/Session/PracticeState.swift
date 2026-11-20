import Foundation

/// Practice session states (ARCHITECTURE.md §3.1.2).
enum PracticeState: Equatable {
    case idle
    case listening
    case ready
    case countIn(Int)           // 3, 2, 1
    case playing
    case paused
    /// Stopped because the iPhone controller dropped. Resumes only once it is connected again.
    case disconnected
    case finished(SessionResult)
}
