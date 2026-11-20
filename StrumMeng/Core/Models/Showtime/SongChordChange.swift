import Foundation

struct SongChordChange: Equatable, Sendable {
    /// Eighth-note slot from the start of the song, not seconds.
    let slot: Int
    let chord: String
}
