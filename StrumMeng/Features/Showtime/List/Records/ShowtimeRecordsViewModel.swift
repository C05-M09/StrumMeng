import Observation

/// Loads the records of one song, for its detail card.
/// Talks to the repository only through the `SongRecordsRepository` protocol.
@MainActor
@Observable
final class ShowtimeRecordsViewModel {
    private(set) var state: ShowtimeRecordsViewState = .loading

    let songID: String
    private(set) var patternID: String?
    private let repository: any SongRecordsRepository

    init(songID: String, patternID: String? = nil, repository: any SongRecordsRepository) {
        self.songID = songID
        self.patternID = patternID
        self.repository = repository
    }

    /// Update the pattern for this record view model and trigger a reload.
    func updatePatternID(_ newPatternID: String) async {
        if patternID != newPatternID {
            patternID = newPatternID
            await load()
        } else if case .loading = state {
            await load()
        }
    }

    /// Stars of the best record (the first row), shown above the card.
    /// `nil` until records are loaded, and when the song has none.
    var bestStars: Int? {
        guard case let .loaded(rows) = state else { return nil }
        return rows.first?.stars
    }

    /// Safe to call repeatedly (every time the card opens, and after a session is saved).
    /// It keeps the current rows on screen while reloading, so there is no flicker.
    func load() async {
        do {
            let results: [SessionResult]
            if let patternID {
                results = try await repository.records(forSong: songID, patternID: patternID, sortedBy: .accuracy)
            } else {
                results = try await repository.records(forSong: songID, sortedBy: .accuracy)
            }
            guard !Task.isCancelled else { return }
            if results.isEmpty {
                state = .empty
            } else {
                state = .loaded(
                    results.enumerated().map {
                        ShowtimeRecordRowModel(rank: $0.offset + 1, result: $0.element)
                    }
                )
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed
        }
    }
}
