import Foundation

enum CompanionEvent: Equatable {
    case typeDigit(Int)
    case deleteDigit
    /// A code saved by an earlier launch, so the player does not type it again.
    case resumePairing(String)
    case linkConnected
    case linkLost
    case disconnect
}
