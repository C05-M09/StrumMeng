import Foundation

enum DeviceSetupEvent: Equatable {
    case linkStateChanged(ControllerConnectionState)
    case linkFailed
    case tapDone
    /// Restart the link: only offered while reconnecting or after a failed start.
    case tapRefresh
    case tapBack
}
