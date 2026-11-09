/// Persists the handoff from successful pairing to the once-only Home tour.
@MainActor
protocol HomeGuidanceStore: AnyObject {
    var isPending: Bool { get }
    var hasCompleted: Bool { get }
    func scheduleAfterPairing()
    func complete()
}
