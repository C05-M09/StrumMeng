import XCTest
@testable import StrumMeng

final class SongBackingTrackInfoTests: XCTestCase {
    private let info = SongBackingTrackInfo(resource: "song", firstBeat: 0.5)

    func test_start_atStepZero_beginsOnTheFilesFirstBeat() {
        let start = info.start(fromSongTime: 0, atHostTime: 100)
        XCTAssertEqual(start.filePosition, 0.5, accuracy: 1e-9)
        XCTAssertEqual(start.hostTime, 100, accuracy: 1e-9)
    }

    func test_start_afterAPause_continuesFromThatPlaceInTheFile() {
        let start = info.start(fromSongTime: 12.25, atHostTime: 200)
        XCTAssertEqual(start.filePosition, 12.75, accuracy: 1e-9)
        XCTAssertEqual(start.hostTime, 200, accuracy: 1e-9)
    }

    func test_start_duringALongLeadIn_waitsAndBeginsTheFileFromItsStart() {
        // 2 s of lead-in, but only 0.5 s of file before the first beat: start 1.5 s later.
        let start = info.start(fromSongTime: -2, atHostTime: 100)
        XCTAssertEqual(start.filePosition, 0, accuracy: 1e-9)
        XCTAssertEqual(start.hostTime, 101.5, accuracy: 1e-9)
    }

    func test_start_inAShortLeadIn_playsTheFilesIntroDuringIt() {
        let start = info.start(fromSongTime: -0.3, atHostTime: 100)
        XCTAssertEqual(start.filePosition, 0.2, accuracy: 1e-9)
        XCTAssertEqual(start.hostTime, 100, accuracy: 1e-9)
    }

    @MainActor func test_everySong_hasABundledRecordingWithAFirstBeat() {
        for song in DefaultSongCatalog.all {
            guard let track = SongBackingTrackInfo.forSong(song.id) else {
                XCTFail("\(song.id) has no recording"); continue
            }
            XCTAssertGreaterThanOrEqual(track.firstBeat, 0, song.id)
            XCTAssertNotNil(Bundle.main.url(forResource: track.resource, withExtension: "mp3"), song.id)
        }
    }

    @MainActor func test_everySongsChart_runsAtItsRecordingsTempo() {
        // Beat-grid fit of the bundled files; the nodes must move at the song's own tempo.
        let measured = ["twinkle-twinkle": 80, "jingle-bells": 120, "abc-song": 100,
                        "row-row-row-your-boat": 110, "down-by-the-riverside": 100]
        for song in DefaultSongCatalog.all {
            XCTAssertEqual(song.bpm, measured[song.id], song.id)
        }
    }

    func test_unknownSong_hasNoRecording() {
        XCTAssertNil(SongBackingTrackInfo.forSong("nope"))
    }
}
