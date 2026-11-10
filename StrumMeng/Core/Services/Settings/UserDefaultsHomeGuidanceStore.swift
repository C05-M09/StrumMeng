import Foundation

@MainActor
final class UserDefaultsHomeGuidanceStore: HomeGuidanceStore {
    private let defaults: UserDefaults
    private static let pendingKey = "onboarding.homeGuidancePending"
    private static let completedKey = "onboarding.homeGuidanceCompleted"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    var isPending: Bool { defaults.bool(forKey: Self.pendingKey) }
    var hasCompleted: Bool { defaults.bool(forKey: Self.completedKey) }

    func scheduleAfterPairing() {
        guard !hasCompleted else { return }
        defaults.set(true, forKey: Self.pendingKey)
    }

    func complete() {
        defaults.set(true, forKey: Self.completedKey)
        defaults.set(false, forKey: Self.pendingKey)
    }
}
