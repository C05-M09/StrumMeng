import Foundation

/// What the iPhone shows: typing the iPad's code, waiting for the iPad, then the strum pad.
enum CompanionState: Equatable {
    case enteringCode(String)
    case connecting(String)
    case connected
}
