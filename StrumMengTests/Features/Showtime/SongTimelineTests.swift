import XCTest
@testable import StrumMeng

@MainActor
final class SongTimelineTests: XCTestCase {
    func test_dummySongsLastExactlyOneMinuteAtTheirOwnBPM() {
        for song in DummySongCatalog().songs {
            let timeline = SongTimeline(song: song)
            XCTAssertEqual(timeline.duration, 60, accuracy: 1e-9)
            XCTAssertEqual(timeline.sessionPattern.strokes.count, timeline.totalSlots)
            XCTAssertEqual(timeline.sessionPattern.loopDuration(at: song.bpm), 60, accuracy: 1e-9)
        }
    }
    func test_chordChangesOnTheSameSlotUsedByLaneAndJudge() {
        let timeline = SongTimeline(song: DummySongCatalog().songs[0])
        XCTAssertEqual(timeline.chord(at: 7), "C")
        XCTAssertEqual(timeline.chord(at: 8), "F")
        XCTAssertEqual(timeline.chordLabels[8], "F")
        XCTAssertEqual(timeline.stroke(at: 0), .down)
        XCTAssertEqual(timeline.stroke(at: 1), .rest)
        XCTAssertEqual(timeline.stroke(at: timeline.totalSlots), .rest)
        XCTAssertEqual(timeline.slotInterval * 8, 3, accuracy: 1e-9)
    }
    func test_stepChords_followTheChart_oneChordPerSlot() {
        let timeline = SongTimeline(song: DummySongCatalog().songs[0])
        let chords = timeline.stepChords
        XCTAssertEqual(chords.count, timeline.totalSlots)
        for slot in [0, 7, 8, 9, timeline.totalSlots - 1] {
            XCTAssertEqual(chords[slot].name, timeline.chord(at: slot), "slot \(slot)")
        }
    }
    func test_stepChords_changeMidBar_onTheChartsSlot() {
        // Riverside changes D -> D7 -> G inside one bar (slots 48, 52, 54).
        guard let song = DefaultSongCatalog.song(forID: "down-by-the-riverside") else { return XCTFail() }
        let chords = SongTimeline(song: song).stepChords
        XCTAssertEqual(chords[51], .d)
        XCTAssertEqual(chords[52], .d7)
        XCTAssertEqual(chords[53], .d7)
        XCTAssertEqual(chords[54], .g)
    }
    func test_stepChords_unknownChordName_playsC() {
        var song = DummySongCatalog().songs[0]
        song.chords = [SongChordChange(slot: 0, chord: "Bm")]
        XCTAssertTrue(SongTimeline(song: song).stepChords.allSatisfy { $0 == .c })
    }
    func test_everyCatalogSong_hasAChordForEveryStep() {
        for song in DefaultSongCatalog.all {
            let timeline = SongTimeline(song: song)
            XCTAssertEqual(timeline.stepChords.count, timeline.totalSlots, song.id)
            XCTAssertEqual(timeline.stepChords.first?.name, song.chords.first?.chord, song.id)
        }
    }
    func test_listenExtractsDistinctPatternsAndGameplayChangesOnTheirScheduledSlot() {
        let one = SongTimeline(song: DummySongCatalog().songs[0])
        XCTAssertEqual(one.previewPatterns.count, 1)
        XCTAssertEqual(one.previewPatterns[0].strokes.count, 8)
        XCTAssertEqual(one.previewPatterns[0].loopDuration(at: 80), 3, accuracy: 1e-9)
        let multiple = SongTimeline(song: DummySongCatalog().songs[1])
        XCTAssertEqual(multiple.previewPatterns.map(\.id), ["subdivision", "foundation"])
        XCTAssertEqual(multiple.stroke(at: 95), .up)
        XCTAssertEqual(multiple.stroke(at: 96), .down)
        XCTAssertEqual(multiple.stroke(at: 97), .rest)
        XCTAssertEqual(multiple.sessionPattern.strokes[97], .rest)
        XCTAssertEqual(multiple.duration, 60, accuracy: 1e-9)
    }
    func test_laneLabelsOnlyInitialChordAndRealChanges() {
        let timeline = SongTimeline(song: DummySongCatalog().songs[1])
        XCTAssertEqual(timeline.chordLabels[0], "C")
        XCTAssertNil(timeline.chordLabels[1])
        XCTAssertNil(timeline.chordLabels[8], "Repeated C in metadata is not a chord change")
        XCTAssertEqual(timeline.chordLabels[16], "F")
        XCTAssertNil(timeline.chordLabels[17])
        XCTAssertEqual(timeline.chordLabels[24], "G")
        XCTAssertEqual(timeline.chordLabels[32], "C")
    }
    func test_emptyArrangementIsSafe() {
        let song = Song(id: "empty", title: "Empty", bpm: 80, patternID: "p", strokes: [],
                        barCount: 0, chords: [])
        let timeline = SongTimeline(song: song)
        XCTAssertEqual(timeline.duration, 0)
        XCTAssertTrue(timeline.strokes.isEmpty)
        XCTAssertTrue(timeline.chordLabels.isEmpty)
        XCTAssertNil(timeline.chord(at: 0))
    }
    func test_listValidatesSongIDsAndUsesInjectedNavigation() {
        var selected: [String] = []
        var backs = 0
        let list = SongListViewModel(catalog: DummySongCatalog(), onSelect: { selected.append($0.id) },
                                    onBack: { backs += 1 })
        list.select("missing")
        XCTAssertTrue(selected.isEmpty)
        list.select(list.songs[0].id)
        XCTAssertEqual(selected, [list.songs[0].id])
        list.back()
        XCTAssertEqual(backs, 1)
    }
}
