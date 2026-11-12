import Foundation
import Observation

/// Which way the last swipe went, so the view can animate the character in the right direction.
enum SongSwipeDirection: Equatable {
    case next
    case previous
}

@MainActor
@Observable
final class SongListViewModel {
    private(set) var state: SongListState
    private(set) var lastSwipe: SongSwipeDirection?

    /// Records of every song by song id.
    let recordsViewModels: [String: ShowtimeRecordsViewModel]
    /// Shown when a song has no records view model (storage could not start).
    let recordsFallbackState: ShowtimeRecordsViewState

    var songs: [Song] {
        state.songs
    }

    @ObservationIgnored private let player: (any ShowtimeSongPlayer)?
    private let onSongSelected: (String) -> Void
    private let onBackRequested: () -> Void

    init(
        songs: [Song]? = nil,
        player: (any ShowtimeSongPlayer)? = nil,
        recordsViewModels: [String: ShowtimeRecordsViewModel] = [:],
        recordsFallbackState: ShowtimeRecordsViewState = .empty,
        onSongSelected: @escaping (String) -> Void,
        onBackRequested: @escaping () -> Void
    ) {
        let ordered = (songs ?? DefaultSongCatalog.all)
            .sorted { $0.suggestedOrder < $1.suggestedOrder }
        state = ordered.isEmpty ? .empty : .loaded(songs: ordered, selectedIndex: 0)
        self.player = player
        self.recordsViewModels = recordsViewModels
        self.recordsFallbackState = recordsFallbackState
        self.onSongSelected = onSongSelected
        self.onBackRequested = onBackRequested
    }

    /// Convenience initializer compatible with catalog injection from tests and previews.
    convenience init(
        catalog: any SongCatalog,
        player: (any ShowtimeSongPlayer)? = nil,
        onSelect: @escaping (Song) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.init(
            songs: catalog.songs,
            player: player,
            onSongSelected: { id in
                if let song = catalog.songs.first(where: { $0.id == id }) {
                    onSelect(song)
                }
            },
            onBackRequested: onBack
        )
    }

    /// The tempo of the song on screen. Read only: nothing can change it.
    var selectedBPM: Int? {
        state.selectedSong?.bpm
    }

    /// Stars of the best record of a song, for the top of the detail card.
    func bestStars(for song: Song) -> Int? {
        recordsViewModels[song.id]?.bestStars
    }

    /// Starts playing the character song for the currently selected song.
    func startPlayback() {
        guard let song = state.selectedSong else { return }
        player?.playSong(id: song.id)
    }

    /// Stops the character song playback.
    func stopPlayback() {
        player?.stop()
    }

    /// Pauses the character song playback (e.g. when app becomes inactive).
    func pausePlayback() {
        player?.pause()
    }

    /// Resumes the character song playback if paused.
    func resumePlayback() {
        player?.resume()
    }

    func select(_ id: String) {
        guard let song = songs.first(where: { $0.id == id }) else { return }
        player?.stop()
        onSongSelected(song.id)
    }

    func back() {
        player?.stop()
        onBackRequested()
    }

    func send(_ event: SongListEvent) {
        state = reduce(state, event)

        switch event {
        case .swipeLeft:
            lastSwipe = .next
            if let song = state.selectedSong {
                player?.playSong(id: song.id)
            }

        case .swipeRight:
            lastSwipe = .previous
            if let song = state.selectedSong {
                player?.playSong(id: song.id)
            }

        case .selectSong:
            guard let song = state.selectedSong else { return }
            player?.stop()
            onSongSelected(song.id)

        case .tapBack:
            player?.stop()
            onBackRequested()
        }
    }

    /// Reloads the records of every song. Call it when a Showtime session was saved, so the card is
    /// up to date when the user is back, without restarting the app.
    func reloadRecords() async {
        for viewModel in recordsViewModels.values {
            await viewModel.load()
        }
    }
}
