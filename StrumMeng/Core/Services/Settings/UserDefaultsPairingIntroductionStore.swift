import Foundation

@MainActor
final class UserDefaultsPairingIntroductionStore: PairingIntroductionStore {
    private let defaults: UserDefaults
    private static let key = "onboarding.pairingIntroductionShown"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var hasShownIntroduction: Bool { defaults.bool(forKey: Self.key) }

    func markIntroductionShown() { defaults.set(true, forKey: Self.key) }
}
