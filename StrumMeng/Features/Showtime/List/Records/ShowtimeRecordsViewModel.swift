import Observation

/// Loads the records of one song, for its detail card.
/// Talks to the repository only through the `SongRecordsRepository` protocol.
@MainActor
@Observable
final class ShowtimeRecordsViewModel {
    private(set) var state: ShowtimeRecordsViewState = .loading

    private let songID: String
    private let repository: any SongRecordsRepository

    init(songID: String, repository: any SongRecordsRepository) {
        self.songID = songID
        self.repository = repository
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
            let results = try await repository.records(forSong: songID, sortedBy: .accuracy)
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
