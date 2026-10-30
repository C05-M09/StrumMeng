import Foundation
@testable import StrumMeng

/// Records what would have been played, instead of making sound.
final class MockGuitarSound: GuitarSound, MetronomeSound {
    struct Strum: Equatable {
        let direction: StrumDirection
        let time: TimeInterval?
        let accent: Double
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

    func prepare() async { prepareCount += 1 }

    func strum(_ direction: StrumDirection, at time: TimeInterval?, accent: Double) {
        strums.append(Strum(direction: direction, time: time, accent: accent))
    }

    func stopStrums() { stopStrumsCount += 1 }

    func click(at time: TimeInterval, accent: Bool) {
        clicks.append(Click(time: time, accent: accent))
    }

    func cancelClicks() { cancelClicksCount += 1 }
}
