import XCTest
@testable import StrumMeng

@MainActor
final class AVShowtimeSongPlayerTests: XCTestCase {
    func test_allShowtimeSongs_haveAudioResourceDefined() {
        for song in DefaultSongCatalog.all {
            let resource = ShowtimeAssets.audioResource(forSongID: song.id)
            XCTAssertNotNil(resource, "Song \(song.id) is missing an audio resource mapping")
        }
    }

    func test_bundledAudioFiles_existInBundle() {
        let bundle = Bundle(for: AVShowtimeSongPlayerTests.self)
        // Test that the audio files are in the main bundle or test bundle
        for song in DefaultSongCatalog.all {
            let resource = ShowtimeAssets.audioResource(forSongID: song.id)!
            let url = Bundle.main.url(forResource: resource, withExtension: "mp3")
                ?? bundle.url(forResource: resource, withExtension: "mp3")
            XCTAssertNotNil(url, "Expected bundled mp3 for \(resource)")
        }
    }

    func test_player_initialState() {
        let player = AVShowtimeSongPlayer()
        XCTAssertNil(player.currentSongID)
        XCTAssertFalse(player.isPlaying)
    }

    func test_player_stopsCleanly() {
        let player = AVShowtimeSongPlayer()
        player.playSong(id: "twinkle-twinkle")
        player.stop()
        XCTAssertNil(player.currentSongID)
        XCTAssertFalse(player.isPlaying)
    }
}

