import Foundation

/// What the iPad's Set Up Device screen shows. Dummy for now: nothing here talks to the link yet.
enum DeviceSetupState: Equatable {
    case searching
    case connected
    case reconnecting
}
