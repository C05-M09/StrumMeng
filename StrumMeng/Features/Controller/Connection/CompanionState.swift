import Foundation

/// What the iPhone shows: typing the iPad's code, waiting for the iPad, then the strum pad.
enum CompanionState: Equatable {
    case enteringCode(String)
    case connecting(String)
    /// No iPad answered this code, which is usually a wrong code or a different Wi-Fi.
    case notFound(String)
    case connected
    /// The iPad was lost after connecting. The pad stays up while the link looks for it again.
    case reconnecting
}
