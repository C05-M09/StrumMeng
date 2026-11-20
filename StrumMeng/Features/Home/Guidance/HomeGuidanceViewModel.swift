import Observation

@MainActor
@Observable
final class HomeGuidanceViewModel {
    private(set) var state: HomeGuidanceState = .dormant
    @ObservationIgnored private let store: any HomeGuidanceStore

    init(store: any HomeGuidanceStore) { self.store = store }

    func send(_ event: HomeGuidanceEvent) {
        if case .homeAppeared = event {
            guard store.isPending, !store.hasCompleted else { return }
        }
        let previous = state
        state = reduce(state, event)
        if previous == .guidebook, state == .finished { store.complete() }
    }
}
