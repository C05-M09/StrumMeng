import Foundation
@testable import StrumMeng

/// Records commands. Tests deliver ticks straight to the view model, so this clock never ticks.
final class MockBeatClock: BeatClock {
    private(set) var startedBPMs: [Int] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var stopCount = 0

    var beatStream: AsyncStream<BeatTick> { AsyncStream { _ in } }

    func start(bpm: Int) async { startedBPMs.append(bpm) }
    func pause() async { pauseCount += 1 }
    func resume() async { resumeCount += 1 }
    func stop() async { stopCount += 1 }
}
