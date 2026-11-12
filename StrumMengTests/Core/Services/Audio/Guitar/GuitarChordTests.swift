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
    ]

    private let roots: [String: Int] = ["C": 0, "G": 7, "Em": 4, "D": 2, "F": 5, "Am": 9]

    /// MIDI notes of the strings that sound, low to high.
    private func sounding(_ chord: GuitarChord) -> [Int] {
        chord.frets.enumerated().compactMap { string, fret in
            fret >= 0 ? KarplusStrong.openMidi[string] + fret : nil
        }
    }

    func test_catalog_holdsTheSixSongChords_inOrder() {
        XCTAssertEqual(GuitarChord.catalog.map(\.name), ["C", "G", "Em", "D", "F", "Am"])
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

    func test_everyChord_soundsExactlyItsTriad() {
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
        for chord in [GuitarChord.g, .em, .f] {
            XCTAssertFalse(chord.frets.contains(-1), "\(chord.name) sounds every string")
        }
    }
}
