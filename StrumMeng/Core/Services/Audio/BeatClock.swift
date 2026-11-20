import Foundation

/// Audio-time beat clock. Ticks once per pattern step; each tick is delivered at its expectedTime.
protocol BeatClock: Sendable {
    var beatStream: AsyncStream<BeatTick> { get }
    func start(bpm: Int) async
    func pause() async
    func resume() async
    func stop() async
}
