import Foundation
@testable import StrumMeng

/// Records when the recording was asked to play, instead of playing it.
final class MockSongBackingTrack: SongBackingTrack {
    struct Play: Equatable {
        let songTime: TimeInterval
        let hostTime: TimeInterval
    }

    private(set) var preparedSongIDs: [String] = []
    private(set) var plays: [Play] = []
    private(set) var stopCount = 0

    func prepare(songID: String) { preparedSongIDs.append(songID) }

    func play(fromSongTime songTime: TimeInterval, atHostTime hostTime: TimeInterval) {
        plays.append(Play(songTime: songTime, hostTime: hostTime))
    }

    func stop() { stopCount += 1 }
}
