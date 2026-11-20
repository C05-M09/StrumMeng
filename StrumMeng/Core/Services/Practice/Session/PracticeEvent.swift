import Foundation

enum PracticeEvent {
    case startListening, replayExample, tapNext, tapReady
    case countInTick, countInDone
    case tapPause, tapResume, tapRestart, tapBackToMenu, tapBackToListen
    case controllerDisconnected, appMovedToBackground
    /// Ready was tapped while the iPhone, the only input, is not connected.
    case readyWithoutController
    case sessionEnded(SessionResult)
}
