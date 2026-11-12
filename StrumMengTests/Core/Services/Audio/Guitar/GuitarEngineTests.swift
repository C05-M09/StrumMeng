import XCTest
@testable import StrumMeng

/// The audio graph itself is checked by ear on a real iPad; these cover which notes get pre-rendered.
final class GuitarEngineTests: XCTestCase {
    /// Soft, medium and hard, each in two takes.
    private let takesPerNote = 3 * 2

    private func notes(_ keys: Set<GuitarEngine.NoteKey>) -> Set<[Int]> {
        Set(keys.map { [$0.string, $0.fret] })
    }

    func test_noteKeys_forC_coverItsFiveSoundingStrings_inEveryLayerAndTake() {
        let keys = GuitarEngine.noteKeys(for: [.c])
        XCTAssertEqual(keys.count, 5 * takesPerNote)
        XCTAssertEqual(notes(keys), [[1, 3], [2, 2], [3, 0], [4, 1], [5, 0]])
    }

    func test_noteKeys_forEveryChord_coverEachOfItsSoundingStrings() {
        for chord in GuitarChord.catalog {
            let expected = Set(chord.frets.enumerated().filter { $0.element >= 0 }.map { [$0.offset, $0.element] })
            XCTAssertEqual(notes(GuitarEngine.noteKeys(for: [chord])), expected, chord.name)
        }
    }

    func test_noteKeys_sharedNotes_areRenderedOnce() {
        // C and Am share the E on the D string, the C on the B string and the open high e.
        let together = GuitarEngine.noteKeys(for: [.c, .am])
        XCTAssertEqual(notes(together).count, 7)
        XCTAssertEqual(together.count, 7 * takesPerNote)
    }

    func test_noteKeys_forTheWholeCatalog_need19Notes() {
        // The sevenths add one note: A7's C# on the B string; D7 and G7 reuse notes of D, Am and F.
        XCTAssertEqual(notes(GuitarEngine.noteKeys(for: GuitarChord.catalog)).count, 19)
    }

    func test_noteKeys_forNoChords_isEmpty() {
        XCTAssertTrue(GuitarEngine.noteKeys(for: []).isEmpty)
    }
}
