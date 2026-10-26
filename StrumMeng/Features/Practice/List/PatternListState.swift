import Foundation

enum PatternListState: Equatable {
    case empty
    case loaded(
        patterns: [StrumPattern],
        selectedPatternID: String,
        selectedBPM: Int
    )

    var patterns: [StrumPattern] {
        guard case let .loaded(patterns, _, _) = self else { return [] }
        return patterns
    }

    var selectedPattern: StrumPattern? {
        guard case let .loaded(patterns, selectedPatternID, _) = self else { return nil }
        return patterns.first { $0.id == selectedPatternID }
    }

    var selectedPatternID: String? {
        guard case let .loaded(_, selectedPatternID, _) = self else { return nil }
        return selectedPatternID
    }

    var selectedBPM: Int? {
        guard case let .loaded(_, _, selectedBPM) = self else { return nil }
        return selectedBPM
    }
}
