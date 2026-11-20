import Foundation

final class UserDefaultsPairCodeStore: PairCodeStore {
    private static let hostKey = "controller.hostPairCode"
    private static let enteredKey = "controller.enteredPairCode"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hostPairCode() -> PairCode {
        if let saved = defaults.string(forKey: Self.hostKey).flatMap(PairCode.init) { return saved }
        let code = PairCode.random()
        defaults.set(code.value, forKey: Self.hostKey)
        return code
    }

    var enteredPairCode: PairCode? {
        defaults.string(forKey: Self.enteredKey).flatMap(PairCode.init)
    }

    func setEnteredPairCode(_ code: PairCode?) {
        defaults.set(code?.value, forKey: Self.enteredKey)
    }
}
