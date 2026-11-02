import Foundation

/// Remembers the pair codes across launches, so pairing is only needed once.
/// Kept apart from SettingsStore: these are not settings the player edits.
protocol PairCodeStore: AnyObject {
    /// The iPad's code. Made the first time it is asked for, then stays the same.
    func hostPairCode() -> PairCode
    /// The code last entered on the iPhone, if it is still paired.
    var enteredPairCode: PairCode? { get }
    /// nil forgets the code, for unpairing.
    func setEnteredPairCode(_ code: PairCode?)
}
