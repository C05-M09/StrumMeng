import XCTest
@testable import StrumMeng

final class AudioBeatClockTests: XCTestCase {
    private var time: TimeInterval = 100

    private func makeClock() -> AudioBeatClock {
        AudioBeatClock(now: { [unowned self] in self.time }, startDelay: 0.3, pollInterval: .seconds(60))
    }

    private func collect(_ stream: AsyncStream<BeatTick>, count: Int) async -> [BeatTick] {
        var ticks: [BeatTick] = []
        for await tick in stream {
            ticks.append(tick)
            if ticks.count == count { break }
        }
        return ticks
    }

    func test_stepInterval_isOneEighthNote() {
        XCTAssertEqual(AudioBeatClock.stepInterval(bpm: 60), 0.5, accuracy: 1e-12)
        XCTAssertEqual(AudioBeatClock.stepInterval(bpm: 80), 0.375, accuracy: 1e-12)
        XCTAssertEqual(AudioBeatClock.stepInterval(bpm: 120), 0.25, accuracy: 1e-12)
    }

    /// Target from CLAUDE.md §7: under 10 ms drift after 1 minute. Every tick is computed from the
    /// anchor, so after a minute it is still exact, at the slowest and fastest tempo.
    func test_afterOneMinute_ticksHaveNoDrift() async {
        for bpm in [40, 80, 120] {
            let clock = makeClock()
            let interval = AudioBeatClock.stepInterval(bpm: bpm)
            let count = Int(60 / interval) + 1
            let stream = clock.beatStream
            time = 100
            await clock.start(bpm: bpm)
            clock.deliverTicks(upTo: 100.3 + 60 + 0.001)
            await clock.stop()

            let ticks = await collect(stream, count: count)
            XCTAssertEqual(ticks.count, count)
            for (n, tick) in ticks.enumerated() {
                XCTAssertEqual(tick.index, n)
                XCTAssertEqual(tick.expectedTime, 100.3 + Double(n) * interval, accuracy: 0.0001, "bpm \(bpm)")
            }
            XCTAssertEqual(ticks.last?.expectedTime ?? 0, 160.3, accuracy: 0.01)
        }
    }

    func test_ticksAreOnlyDeliveredOnceTheyAreDue() async {
        let clock = makeClock()
        let stream = clock.beatStream
        await clock.start(bpm: 80)
        clock.deliverTicks(upTo: 100.29)
        clock.deliverTicks(upTo: 100.3 + 0.375 + 0.001)
        await clock.stop()
        let ticks = await collect(stream, count: 2)
        XCTAssertEqual(ticks.map(\.index), [0, 1])
    }

    func test_resume_continuesWithTheNextIndexFromTheNewTime() async {
        let clock = makeClock()
        let stream = clock.beatStream
        await clock.start(bpm: 80)
        clock.deliverTicks(upTo: 100.3 + 0.375 + 0.001)       // ticks 0 and 1
        await clock.pause()
        time = 200
        await clock.resume()
        clock.deliverTicks(upTo: 200.3 + 0.001)
        await clock.stop()
        let ticks = await collect(stream, count: 3)
        XCTAssertEqual(ticks.map(\.index), [0, 1, 2])
        XCTAssertEqual(ticks[2].expectedTime, 200.3, accuracy: 1e-9)
    }
}
