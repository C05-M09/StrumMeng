import Foundation

enum DeviceSetupEvent: Equatable {
    case linkStateChanged(ControllerConnectionState)
    case linkFailed
    case tapDone
    case tapBack
}
