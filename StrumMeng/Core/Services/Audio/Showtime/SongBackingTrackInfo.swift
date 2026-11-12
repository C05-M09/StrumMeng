import Foundation

/// Where a song's recording lives and where its first beat is, so that beat lands on node 1.
nonisolated struct SongBackingTrackInfo: Sendable, Equatable {
    /// mp3 name in the app bundle, without the extension.
    let resource: String
    /// Seconds into the file where bar 1 starts: the first node lands here.
    let firstBeat: TimeInterval

    /// The bundled recordings, measured with a beat-grid fit of each file (2026-11-12: 80, 120,
    /// 100, 110 and 100 BPM). Four start on bar 1 at the top of the file; Riverside opens with
    /// silence and three sixteenth pickups (from 1.93 s) into bar 1 at 2.38 s.
    static let all: [String: SongBackingTrackInfo] = [
        "twinkle-twinkle": .init(resource: "1_foundation_twinkle_twinkle", firstBeat: 0),
        "jingle-bells": .init(resource: "2_subdivision_jingle_bells", firstBeat: 0),
        "abc-song": .init(resource: "3_syncopation_abc_song", firstBeat: 0),
        "row-row-row-your-boat": .init(resource: "4_upbeat_row_row_row_your_boat", firstBeat: 0),
        "down-by-the-riverside": .init(resource: "5_driving_pop_down_by_the_riverside", firstBeat: 2.38),
    ]

    static func forSong(_ songID: String) -> SongBackingTrackInfo? {
        all[songID]
    }

    /// Where to start in the file and when, so `songTime` sounds at `hostTime`. When that point is
    /// before the file begins (a lead-in longer than the file's intro), the file starts later, at
    /// its very beginning.
    func start(fromSongTime songTime: TimeInterval,
               atHostTime hostTime: TimeInterval) -> (filePosition: TimeInterval, hostTime: TimeInterval) {
        let position = firstBeat + songTime
        guard position < 0 else { return (position, hostTime) }
        return (0, hostTime - position)
    }
}
