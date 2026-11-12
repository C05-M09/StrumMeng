import XCTest
@testable import StrumMeng

@MainActor
final class PatternStrumDemoPlayerTests: XCTestCase {
    private var now: TimeInterval = 100
    private func pattern() -> StrumPattern { SongTimeline(song: DummySongCatalog().songs[1]).previewPatterns[0] }
    func test_firstLoopUnlocksAtBoundaryThenContinuesWithoutRepeatedCompletion() async {
        let clock = MockBeatClock(); let sound = MockGuitarSound()
        let player = PatternStrumDemoPlayer(clock: clock, sound: sound, now: { self.now })
        var iterator = player.events.makeAsyncIterator()
        await player.start(pattern: pattern(), bpm: 80)
        for index in 0..<8 {
            now = 100 + Double(index) * 0.375
            player.receive(BeatTick(index: index, expectedTime: now))
            let event = await iterator.next()
            XCTAssertEqual(event, .step(index))
        }
        now = 103
        player.receive(BeatTick(index: 8, expectedTime: now))
        let completed = await iterator.next()
        let firstAgain = await iterator.next()
        XCTAssertEqual(completed, .finished)
        XCTAssertEqual(firstAgain, .step(0))
        XCTAssertEqual(sound.strums[0].direction, .down)
        XCTAssertEqual(sound.strums[1].direction, .up)
        XCTAssertEqual(sound.strums[1].time, 100.375)
        for index in 9...16 {
            player.receive(BeatTick(index: index, expectedTime: 100 + Double(index) * 0.375))
            let step = await iterator.next()
            XCTAssertEqual(step, .step(index % 8))
        }
        await player.stop()
    }
    func test_restsAreSilentAndSchedulingUsesSelectedBPM() async {
        let sound = MockGuitarSound()
        let player = PatternStrumDemoPlayer(clock: MockBeatClock(), sound: sound, now: { self.now })
        let pattern = SongTimeline(song: DummySongCatalog().songs[0]).previewPatterns[0]
        await player.start(pattern: pattern, bpm: 120)
        for index in 0..<8 { player.receive(BeatTick(index: index, expectedTime: 100 + Double(index) * 0.25)) }
        XCTAssertEqual(sound.strums.compactMap(\.time), [100, 100.5, 101, 101.5, 102])
        XCTAssertTrue(sound.strums.allSatisfy { $0.direction == .down })
        await player.stop()
    }
    func test_pauseFreezesTimeAndResumeReplacesCancelledScheduledStrum() async {
        let clock = MockBeatClock(); let sound = MockGuitarSound()
        let player = PatternStrumDemoPlayer(clock: clock, sound: sound, now: { self.now })
        await player.start(pattern: pattern(), bpm: 80)
        player.receive(BeatTick(index: 0, expectedTime: 100))
        now = 100.2
        await player.pause()
        now = 120
        XCTAssertEqual(player.elapsed, 0.2, accuracy: 1e-9)
        let count = sound.strums.count
        player.receive(BeatTick(index: 1, expectedTime: 120))
        XCTAssertEqual(sound.strums.count, count)
        await player.resume()
        player.receive(BeatTick(index: 1, expectedTime: 120.3))
        XCTAssertEqual(sound.strums[count].direction, .up)
        XCTAssertEqual(clock.resumeCount, 1)
        await player.stop()
        XCTAssertEqual(player.elapsed, 0)
        XCTAssertGreaterThan(sound.stopStrumsCount, 0)
    }
}
