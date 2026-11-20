import XCTest
@testable import StrumMeng

/// The defaults Practice relies on: without a chord, the guitar plays and prepares C.
final class GuitarSoundTests: XCTestCase {
    func test_strumWithoutChord_playsC() {
        let sound = MockGuitarSound()
        sound.strum(.up, at: 2.5, accent: 0.9)
        XCTAssertEqual(sound.strums, [.init(direction: .up, time: 2.5, accent: 0.9, chord: .c)])
    }

    func test_strumWithChord_playsThatChord() {
        let sound = MockGuitarSound()
        sound.strum(.down, chord: .am, at: nil, accent: 1)
        XCTAssertEqual(sound.strums.map(\.chord), [.am])
    }

    func test_prepareWithoutChords_preparesCOnly() async {
        let sound = MockGuitarSound()
        await sound.prepare()
        XCTAssertEqual(sound.preparedChords, [[.c]])
    }

    func test_prepareWithChords_preparesThoseChords() async {
        let sound = MockGuitarSound()
        await sound.prepare(chords: [.g, .d, .em])
        XCTAssertEqual(sound.preparedChords, [[.g, .d, .em]])
    }
}
