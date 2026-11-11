/// Persists the handoff from leaving device setup to the once-only Home tour.
@MainActor
protocol HomeGuidanceStore: AnyObject {
    var isPending: Bool { get }
    var hasCompleted: Bool { get }
    func scheduleAfterSetup()
    func complete()
}
