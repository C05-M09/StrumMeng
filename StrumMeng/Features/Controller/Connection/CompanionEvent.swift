import Foundation

enum CompanionEvent: Equatable {
    case typeDigit(Int)
    case deleteDigit
    /// The keypad's clear key: empties the code, or stops looking for the iPad while connecting.
    case clearCode
    /// A code saved by an earlier launch, so the player does not type it again.
    case resumePairing(String)
    case linkConnected
    case connectionTimedOut
    case linkLost
    case disconnect
}
