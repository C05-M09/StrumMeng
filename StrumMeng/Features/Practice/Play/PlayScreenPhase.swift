import Foundation

/// What the Play screen overlays. UI-only until the team's PracticeState lands.
enum PlayScreenPhase: Equatable {
    case ready            // "READY?" over the dimmed screen, waiting for the player
    case countIn(Int)     // 3, 2, 1
    case playing
    case paused           // "Are you sure want to end the session?"
}
