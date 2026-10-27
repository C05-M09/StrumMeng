import Foundation

enum PracticeEvent {
    case startListening, replayExample, tapNext, tapReady
    case countInTick, countInDone
    case tapPause, tapResume, tapRestart, tapBackToMenu
    case controllerDisconnected, appMovedToBackground
    case sessionEnded(SessionResult)
}
