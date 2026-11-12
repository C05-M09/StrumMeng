import Foundation
@testable import StrumMeng

@MainActor
final class MockShowtimeSongPlayer: ShowtimeSongPlayer {
    private(set) var currentSongID: String?
    private(set) var isPlaying: Bool = false
    private(set) var playSongCalls: [String] = []
    private(set) var stopCount = 0
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var volumes: [Double] = []

    func playSong(id: String) {
        playSongCalls.append(id)
        currentSongID = id
        isPlaying = true
    }

    func stop() {
        stopCount += 1
        currentSongID = nil
        isPlaying = false
    }

    func pause() {
        pauseCount += 1
        isPlaying = false
    }

    func resume() {
        resumeCount += 1
        if currentSongID != nil {
            isPlaying = true
        }
    }

    func setVolume(_ volume: Double) {
        volumes.append(volume)
    }
}

