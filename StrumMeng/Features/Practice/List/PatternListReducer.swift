import Foundation

func reduce(_ state: PatternListState, _ event: PatternListEvent) -> PatternListState {
    guard case let .loaded(patterns, selectedPatternID, selectedBPM) = state else {
        return state
    }

    switch event {
    case let .selectPattern(id):
        guard let pattern = patterns.first(where: { $0.id == id }) else {
            return state
        }
        return .loaded(
            patterns: patterns,
            selectedPatternID: pattern.id,
            selectedBPM: PracticeTempoConfig.clamped(pattern.defaultBPM)
        )

    case .decreaseBPM:
        return .loaded(
            patterns: patterns,
            selectedPatternID: selectedPatternID,
            selectedBPM: PracticeTempoConfig.clamped(selectedBPM - PracticeTempoConfig.step)
        )

    case .increaseBPM:
        return .loaded(
            patterns: patterns,
            selectedPatternID: selectedPatternID,
            selectedBPM: PracticeTempoConfig.clamped(selectedBPM + PracticeTempoConfig.step)
        )

    case let .setBPM(bpm):
        return .loaded(
            patterns: patterns,
            selectedPatternID: selectedPatternID,
            selectedBPM: PracticeTempoConfig.clamped(bpm)
        )

    case .tapPlay, .tapBack:
        return state
    }
}
