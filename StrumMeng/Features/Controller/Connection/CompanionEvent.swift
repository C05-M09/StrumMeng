import Foundation

enum CompanionEvent: Equatable {
    case typeDigit(Int)
    case deleteDigit
    /// The iPad answered. Comes from a dummy delay until the link is wired.
    case linkConnected
    case disconnect
}
