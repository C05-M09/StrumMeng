import Foundation
import Observation

@MainActor
@Observable
final class PatternListViewModel {
    private(set) var state: PatternListState
    let recordsViewModels: [String: RecordsViewModel]
    let recordsFallbackState: RecordsViewState

    private let onListenRequested: (String, Int) -> Void
    private let onBackRequested: () -> Void

    init(
        patterns: [StrumPattern]? = nil,
        recordsViewModels: [String: RecordsViewModel] = [:],
        recordsFallbackState: RecordsViewState = .empty,
        onListenRequested: @escaping (String, Int) -> Void,
        onBackRequested: @escaping () -> Void
    ) {
        let orderedPatterns = (patterns ?? PatternCatalog.all)
            .sorted { $0.suggestedOrder < $1.suggestedOrder }

        if let firstPattern = orderedPatterns.first {
            state = .loaded(
                patterns: orderedPatterns,
                selectedPatternID: firstPattern.id,
                selectedBPM: PracticeTempoConfig.clamped(firstPattern.defaultBPM)
            )
        } else {
            state = .empty
        }

        self.onListenRequested = onListenRequested
        self.onBackRequested = onBackRequested
        self.recordsViewModels = recordsViewModels
        self.recordsFallbackState = recordsFallbackState
    }

    func send(_ event: PatternListEvent) {
        state = reduce(state, event)

        switch event {
        case .tapPlay:
            guard
                let patternID = state.selectedPatternID,
                let bpm = state.selectedBPM
            else { return }
            onListenRequested(patternID, bpm)

        case .tapBack:
            onBackRequested()

        case .selectPattern, .decreaseBPM, .increaseBPM, .setBPM:
            break
        }
    }
}
