import Foundation
import Observation

@MainActor
@Observable
final class PatternListViewModel {
    private(set) var state: PatternListState
    let recordsViewModels: [String: RecordsViewModel]
    let recordsFallbackState: RecordsViewState
    private(set) var recordsRefreshID = 0

    /// Last played tempo per pattern. A pattern that was never played has no entry.
    @ObservationIgnored private var rememberedBPMs: [String: Int] = [:]
    @ObservationIgnored private let lastPlayedBPM: (String) async -> Int?
    private let onListenRequested: (String, Int) -> Void
    private let onBackRequested: () -> Void

    init(
        patterns: [StrumPattern]? = nil,
        recordsViewModels: [String: RecordsViewModel] = [:],
        recordsFallbackState: RecordsViewState = .empty,
        lastPlayedBPM: @escaping (String) async -> Int? = { _ in nil },
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
        self.lastPlayedBPM = lastPlayedBPM
    }

    func send(_ event: PatternListEvent) {
        state = reduce(state, event)

        switch event {
        case let .selectPattern(id):
            // The reducer resets to the pattern's default tempo; a pattern that was played
            // before goes back to the tempo it was last played at.
            applyRememberedBPM(for: id)

        case .tapPlay:
            guard
                let patternID = state.selectedPatternID,
                let bpm = state.selectedBPM
            else { return }
            onListenRequested(patternID, bpm)

        case .tapBack:
            onBackRequested()

        case .decreaseBPM, .increaseBPM, .setBPM:
            break
        }
    }

    /// Loads the last played tempo of every pattern once at launch. The selected pattern follows it
    /// right away.
    func loadRememberedBPMs() async {
        await refreshRememberedBPMs()
        if let id = state.selectedPatternID {
            applyRememberedBPM(for: id)
        }
    }

    /// Reloads the records of every pattern. Called once a session is saved, so the lists are
    /// already up to date when the user is back, without relying on the screen's appear events.
    func reloadRecords() async {
        for viewModel in recordsViewModels.values {
            await viewModel.load()
        }
        // Only the memory is updated here, not the tempo on screen: after Retry the list shows
        // the tempo that was just chosen.
        await refreshRememberedBPMs()
        recordsRefreshID += 1
    }

    private func refreshRememberedBPMs() async {
        for pattern in state.patterns {
            rememberedBPMs[pattern.id] = await lastPlayedBPM(pattern.id)
        }
    }

    private func applyRememberedBPM(for patternID: String) {
        guard
            state.selectedPatternID == patternID,
            let bpm = rememberedBPMs[patternID]
        else { return }
        state = reduce(state, .setBPM(bpm))
    }
}
