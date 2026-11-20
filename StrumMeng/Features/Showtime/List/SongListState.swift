import Foundation

enum SongListState: Equatable {
    case empty
    case loaded(songs: [Song], selectedIndex: Int)

    var songs: [Song] {
        guard case let .loaded(songs, _) = self else { return [] }
        return songs
    }

    var selectedIndex: Int? {
        guard case let .loaded(_, selectedIndex) = self else { return nil }
        return selectedIndex
    }

    var selectedSong: Song? {
        guard case let .loaded(songs, selectedIndex) = self,
              songs.indices.contains(selectedIndex)
        else { return nil }
        return songs[selectedIndex]
    }
}
