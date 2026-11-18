import Foundation

@MainActor
final class UserDefaultsPracticeGuidanceStore: PracticeGuidanceStore {
    private let defaults: UserDefaults
    private static let completedKey = "practice.guidanceCompleted"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var hasCompletedGuidance: Bool { defaults.bool(forKey: Self.completedKey) }

    func completeGuidance() {
        defaults.set(true, forKey: Self.completedKey)
    }

    func resetGuidance() {
        defaults.removeObject(forKey: Self.completedKey)
    }
}
