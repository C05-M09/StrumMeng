import Foundation

enum CompanionEvent: Equatable {
    case typeDigit(Int)
    case deleteDigit
    /// The keypad's check key: connects with the full code, or tries it again after not found.
    case confirmCode
    /// A code saved by an earlier launch, so the player does not type it again.
    case resumePairing(String)
    case linkConnected
    case connectionTimedOut
    case linkLost
    case disconnect
}
