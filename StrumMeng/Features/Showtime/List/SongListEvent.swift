import Foundation

enum SongListEvent: Equatable {
    /// Finger moves left: the next song comes in from the right.
    case swipeLeft
    /// Finger moves right: the previous song comes in from the left.
    case swipeRight
    /// The user chose the song on screen (Play on the detail card).
    case selectSong
    case tapBack
}
