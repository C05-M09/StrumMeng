import XCTest
@testable import StrumMeng

final class ShowtimeSongInfoTests: XCTestCase {
    func test_songInfo_usesTheSongsTitleLengthAndChordsInOrder() {
        // 8 bars of 4 beats at 80 BPM = 24 s.
        let song = Song(id: "test-song", title: "Test Song", bpm: 80, patternID: "foundation",
            strokes: [.down], barCount: 8,
            chords: [SongChordChange(slot: 0, chord: "G"), SongChordChange(slot: 8, chord: "C"),
                     SongChordChange(slot: 16, chord: "G"), SongChordChange(slot: 24, chord: "D7")])
        let info = ShowtimeSongInfo(song: song)
        XCTAssertEqual(info.title, "Test Song")
        XCTAssertEqual(info.durationLabel, "24 sec")
        XCTAssertEqual(info.chords, ["G", "C", "D7"])
    }
}
