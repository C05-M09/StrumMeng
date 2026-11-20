import XCTest
@testable import StrumMeng

final class GuitarChordTests: XCTestCase {
    /// Pitch classes, C = 0 … B = 11.
    private let expectedTriads: [String: Set<Int>] = [
        "C": [0, 4, 7],   // C E G
        "G": [7, 11, 2],  // G B D
        "Em": [4, 7, 11], // E G B
        "D": [2, 6, 9],   // D F# A
        "F": [5, 9, 0],   // F A C
        "Am": [9, 0, 4],  // A C E
        "A7": [9, 1, 4, 7],  // A C# E G
        "D7": [2, 6, 9, 0],  // D F# A C
        "G7": [7, 11, 2, 5], // G B D F
    ]

    private let roots: [String: Int] = ["C": 0, "G": 7, "Em": 4, "D": 2, "F": 5, "Am": 9,
                                        "A7": 9, "D7": 2, "G7": 7]

    /// MIDI notes of the strings that sound, low to high.
    private func sounding(_ chord: GuitarChord) -> [Int] {
        chord.frets.enumerated().compactMap { string, fret in
            fret >= 0 ? KarplusStrong.openMidi[string] + fret : nil
        }
    }

    func test_catalog_holdsTheSongChords_inOrder() {
        XCTAssertEqual(GuitarChord.catalog.map(\.name), ["C", "G", "Em", "D", "F", "Am", "A7", "D7", "G7"])
    }

    func test_named_findsACatalogChord() {
        XCTAssertEqual(GuitarChord.named("D7"), .d7)
        XCTAssertEqual(GuitarChord.named("Em"), .em)
    }

    func test_named_unknownOrMiscasedName_isNil() {
        XCTAssertNil(GuitarChord.named("Bm"))
        XCTAssertNil(GuitarChord.named("em"))
        XCTAssertNil(GuitarChord.named(""))
    }

    @MainActor func test_everyChordOfTheSongCatalog_isPlayable() {
        for song in DefaultSongCatalog.all {
            for change in song.chords {
                XCTAssertNotNil(GuitarChord.named(change.chord), "\(song.id): \(change.chord)")
            }
        }
        for name in DefaultSongCatalog.allowedChords {
            XCTAssertNotNil(GuitarChord.named(name), name)
        }
    }

    func test_catalog_namesAreUnique() {
        XCTAssertEqual(Set(GuitarChord.catalog.map(\.name)).count, GuitarChord.catalog.count)
    }

    func test_everyChord_hasAFretForEachOfTheSixStrings() {
        for chord in GuitarChord.catalog {
            XCTAssertEqual(chord.frets.count, 6, chord.name)
            XCTAssertTrue(chord.frets.allSatisfy { (-1...5).contains($0) }, chord.name)
        }
    }

    func test_everyChord_soundsExactlyItsNotes() {
        for chord in GuitarChord.catalog {
            let pitchClasses = Set(sounding(chord).map { $0 % 12 })
            XCTAssertEqual(pitchClasses, expectedTriads[chord.name], chord.name)
        }
    }

    func test_everyChord_hasItsRootInTheBass() {
        for chord in GuitarChord.catalog {
            XCTAssertEqual(sounding(chord).first.map { $0 % 12 }, roots[chord.name], chord.name)
        }
    }

    func test_fBarre_soundsAllSixStrings() {
        XCTAssertEqual(GuitarChord.f.frets, [1, 3, 3, 2, 1, 1])
        XCTAssertFalse(GuitarChord.f.frets.contains(-1))
    }

    func test_mutedStrings_matchTheUsualShapes() {
        XCTAssertEqual(GuitarChord.c.frets.firstIndex(of: -1), 0, "C mutes low E")
        XCTAssertEqual(GuitarChord.am.frets.firstIndex(of: -1), 0, "Am mutes low E")
        XCTAssertEqual(GuitarChord.d.frets.prefix(2), [-1, -1], "D mutes low E and A")
        XCTAssertEqual(GuitarChord.d7.frets.prefix(2), [-1, -1], "D7 mutes low E and A")
        XCTAssertEqual(GuitarChord.a7.frets.firstIndex(of: -1), 0, "A7 mutes low E")
        for chord in [GuitarChord.g, .em, .f, .g7] {
            XCTAssertFalse(chord.frets.contains(-1), "\(chord.name) sounds every string")
        }
    }
}
