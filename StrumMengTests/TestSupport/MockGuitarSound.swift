import Foundation
@testable import StrumMeng

/// Records what would have been played, instead of making sound.
final class MockGuitarSound: GuitarSound, MetronomeSound {
    struct Strum: Equatable {
        let direction: StrumDirection
        let time: TimeInterval?
        let accent: Double
        /// Defaults to C so tests written before chords existed still compare equal.
        var chord: GuitarChord = .c
    }

    struct Click: Equatable {
        let time: TimeInterval
        let accent: Bool
    }

    private(set) var strums: [Strum] = []
    private(set) var clicks: [Click] = []
    private(set) var prepareCount = 0
    private(set) var stopStrumsCount = 0
    private(set) var cancelClicksCount = 0

    private(set) var preparedChords: [[GuitarChord]] = []

    func prepare(chords: [GuitarChord]) async {
        prepareCount += 1
        preparedChords.append(chords)
    }

    func strum(_ direction: StrumDirection, chord: GuitarChord, at time: TimeInterval?, accent: Double) {
        strums.append(Strum(direction: direction, time: time, accent: accent, chord: chord))
    }

    func stopStrums() { stopStrumsCount += 1 }

    func click(at time: TimeInterval, accent: Bool) {
        clicks.append(Click(time: time, accent: accent))
    }

    func cancelClicks() { cancelClicksCount += 1 }
}
