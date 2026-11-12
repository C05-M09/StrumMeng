import Foundation

/// Pure transitions of the song list. Swiping wraps around: last -> first and first -> last.
/// There is no BPM event: a song's tempo is fixed.
func reduce(_ state: SongListState, _ event: SongListEvent) -> SongListState {
    guard case let .loaded(songs, selectedIndex) = state, !songs.isEmpty else {
        return state
    }

    switch event {
    case .swipeLeft:
        return .loaded(songs: songs, selectedIndex: (selectedIndex + 1) % songs.count)

    case .swipeRight:
        return .loaded(songs: songs, selectedIndex: (selectedIndex - 1 + songs.count) % songs.count)

    case .selectSong, .tapBack:
        return state
    }
}
