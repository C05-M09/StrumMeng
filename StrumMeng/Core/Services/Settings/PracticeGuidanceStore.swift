/// Remembers whether the first-play guidance modal (2_Guidance) has already been completed.
@MainActor
protocol PracticeGuidanceStore: AnyObject {
    var hasCompletedGuidance: Bool { get }
    func completeGuidance()
    func resetGuidance()
}

@MainActor
final class InMemoryPracticeGuidanceStore: PracticeGuidanceStore {
    var hasCompletedGuidance: Bool

    init(hasCompletedGuidance: Bool = false) {
        self.hasCompletedGuidance = hasCompletedGuidance
    }

    func completeGuidance() {
        hasCompletedGuidance = true
    }

    func resetGuidance() {
        hasCompletedGuidance = false
    }
}
