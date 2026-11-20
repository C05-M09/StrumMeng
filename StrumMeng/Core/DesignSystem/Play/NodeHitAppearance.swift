import Foundation

/// How a node is drawn at one moment of its hit animation.
struct NodeHitAppearance: Equatable {
    var scale: Double = 1
    var opacity: Double = 1
    /// The node stays in the hit ring instead of following the lane (a hit).
    var snapsToRing = false
    /// The node loses its colour (a miss).
    var greyedOut = false

    static let resting = NodeHitAppearance()
}
