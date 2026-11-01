import Foundation

enum DeviceSetupEvent: Equatable {
    /// Placeholder for the link's state changes, so every state can be seen before the link is wired.
    case simulateNextState
    case tapDone
    case tapBack
}
