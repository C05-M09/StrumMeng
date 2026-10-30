import XCTest
@testable import StrumMeng

final class StrumVoicingTests: XCTestCase {
    /// No randomness in timing or loudness, so offsets and velocities are exact.
    private var steady: GuitarSoundSettings {
        var settings = GuitarSoundSettings.favourite
        settings.humanize = 0
        return settings
    }

    private func notes(_ direction: StrumDirection, settings: GuitarSoundSettings? = nil,
                       accent: Double = 1, seed: UInt64 = 1) -> [StrumNote] {
        var random = SeededRandom(seed: seed)
        return StrumVoicing.notes(chord: .c, direction: direction, accent: accent,
                                  settings: settings ?? steady, random: &random)
    }

    func test_downstroke_playsTheFiveStringsOfC_lowToHigh() {
        let played = notes(.down)
        XCTAssertEqual(played.map(\.string), [1, 2, 3, 4, 5], "Low E is muted in C")
        XCTAssertEqual(played.map(\.fret), [3, 2, 0, 1, 0])
    }

    func test_downstroke_crossesTheStringsInTheStrumSpread() {
        let offsets = notes(.down).map(\.offset)
        XCTAssertEqual(offsets, offsets.sorted())
        // The muted low E keeps its place in time, so the A string starts one fifth in.
        XCTAssertEqual(offsets.first ?? -1, 0.045 / 5, accuracy: 1e-9)
        XCTAssertEqual(offsets.last ?? -1, 0.045, accuracy: 1e-9)
    }

    func test_upstroke_goesHighToLow_andIsQuicker() {
        var settings = steady
        settings.upstrokeBass = 1
        let played = notes(.up, settings: settings)
        XCTAssertEqual(played.map(\.string), [5, 4, 3, 2, 1])
        XCTAssertEqual(played.last?.offset ?? -1, 0.045 * 0.85 * 4 / 5, accuracy: 1e-9)
    }

    func test_upstroke_withoutBass_skipsTheBassStrings() {
        var settings = steady
        settings.upstrokeBass = 0
        XCTAssertFalse(notes(.up, settings: settings).contains { $0.string <= 1 })
    }

    func test_softerAccent_givesSofterNotes() {
        let hard = notes(.down, accent: 1).map(\.velocity)
        let soft = notes(.down, accent: 0.5).map(\.velocity)
        for (h, s) in zip(hard, soft) { XCTAssertGreaterThan(h, s) }
    }

    func test_humanize_staysWithinItsBounds() {
        for seed in 1...200 as ClosedRange<UInt64> {
            for note in notes(.down, settings: .favourite, seed: seed) {
                XCTAssertGreaterThanOrEqual(note.offset, 0)
                XCTAssertLessThan(note.offset, 0.045 * 1.15 + 0.0015 + 1e-9)
                XCTAssertTrue((0.12...1).contains(note.velocity))
            }
        }
    }

    func test_layer_picksSoftMediumOrHard() {
        XCTAssertEqual(StrumVoicing.layer(for: 0.3), 0)
        XCTAssertEqual(StrumVoicing.layer(for: 0.6), 1)
        XCTAssertEqual(StrumVoicing.layer(for: 0.9), 2)
    }

    func test_favourite_matchesTheChosenPrototypeSettings() {
        let favourite = GuitarSoundSettings.favourite
        XCTAssertEqual(favourite.instrument, .nylon)
        XCTAssertEqual(favourite.strumSpreadMs, 45)
        XCTAssertEqual(favourite.humanize, 1)
        XCTAssertEqual(favourite.sustain, 1.5)
        XCTAssertEqual(favourite.brightness, 0.5)
        XCTAssertEqual(favourite.upstrokeBass, 0.3)
        XCTAssertEqual(favourite.reverb, 0.25)
        XCTAssertEqual(favourite.volume, 0.8)
    }
}
