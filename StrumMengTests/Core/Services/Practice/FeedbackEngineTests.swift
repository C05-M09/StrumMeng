import XCTest
@testable import StrumMeng

final class FeedbackEngineTests: XCTestCase {
    private let step = AudioBeatClock.stepInterval(bpm: 80)    // 0.375 s

    private func makeEngine(offset: TimeInterval = 0) -> FeedbackEngine {
        FeedbackEngine(config: .standard, latencyOffset: offset, stepInterval: step)
    }

    private func beat(_ index: Int, at time: TimeInterval, _ direction: StrumDirection = .down) -> BeatTarget {
        BeatTarget(index: index, expectedTime: time, direction: direction)
    }

    func test_perfectStrumAfterTheBeat_isFinalisedImmediately() {
        var engine = makeEngine()
        XCTAssertTrue(engine.addBeat(beat(0, at: 10)).isEmpty)
        let events = engine.addStrum(PracticeFixtures.strum(at: 10.02))
        XCTAssertEqual(events.map(\.result), [.perfect])
        XCTAssertTrue(engine.openBeats.isEmpty)
    }

    func test_perfectStrumJustBeforeTheBeat_isFinalisedWhenTheBeatArrives() {
        var engine = makeEngine()
        XCTAssertTrue(engine.addStrum(PracticeFixtures.strum(at: 9.98)).isEmpty)
        XCTAssertEqual(engine.addBeat(beat(0, at: 10)).map(\.result), [.perfect])
    }

    func test_tooEarlyStrum_isFinalisedWhenTheWindowCloses() {
        var engine = makeEngine()
        _ = engine.addStrum(PracticeFixtures.strum(at: 9.9))
        XCTAssertTrue(engine.addBeat(beat(0, at: 10)).isEmpty)
        XCTAssertTrue(engine.close(upTo: 10.04).isEmpty)
        XCTAssertEqual(engine.close(upTo: 10.05).map(\.result), [.tooEarly])
    }

    func test_tooEarlyThenPerfect_inOneWindow_endsAsPerfect() {
        var engine = makeEngine()
        _ = engine.addStrum(PracticeFixtures.strum(at: 9.9))
        _ = engine.addBeat(beat(0, at: 10))
        XCTAssertEqual(engine.addStrum(PracticeFixtures.strum(at: 10.01)).map(\.result), [.perfect])
    }

    func test_wrongDirection_isMissImmediately() {
        var engine = makeEngine()
        _ = engine.addBeat(beat(0, at: 10, .up))
        XCTAssertEqual(engine.addStrum(PracticeFixtures.strum(at: 10.0, .down)).map(\.result), [.miss])
        XCTAssertTrue(engine.openBeats.isEmpty)
    }

    func test_wrongDirectionEarly_locksTheMissEvenIfARightOneFollows() {
        var engine = makeEngine()
        _ = engine.addBeat(beat(0, at: 10))
        XCTAssertEqual(engine.addStrum(PracticeFixtures.strum(at: 9.97, .up)).map(\.result), [.miss])
        XCTAssertTrue(engine.addStrum(PracticeFixtures.strum(at: 10.0, .down)).isEmpty)
    }

    func test_noStrum_isMissWhenTheWindowCloses() {
        var engine = makeEngine()
        _ = engine.addBeat(beat(0, at: 10))
        XCTAssertEqual(engine.nextDeadline ?? 0, 10.05, accuracy: 1e-9)
        XCTAssertEqual(engine.close(upTo: 10.05).map(\.result), [.miss])
        XCTAssertNil(engine.nextDeadline)
    }

    func test_lateStrum_closesTheBeatAsMiss() {
        var engine = makeEngine()
        _ = engine.addBeat(beat(0, at: 10))
        XCTAssertEqual(engine.addStrum(PracticeFixtures.strum(at: 10.08)).map(\.result), [.miss])
    }

    func test_oneStrum_satisfiesOnlyOneBeat() {
        var engine = makeEngine()
        _ = engine.addBeat(beat(0, at: 10))
        var events = engine.addStrum(PracticeFixtures.strum(at: 10.04))
        events += engine.addBeat(beat(1, at: 10 + step))
        events += engine.close(upTo: 11)
        XCTAssertEqual(events.map(\.result), [.perfect, .miss])
    }

    func test_duplicateStrum_isCountedOnce_evenAfterItWasUsed() {
        var engine = makeEngine()
        let strum = PracticeFixtures.strum(at: 10.0)
        _ = engine.addBeat(beat(0, at: 10))
        XCTAssertEqual(engine.addStrum(strum).count, 1)
        let resent = StrumEvent(id: strum.id, direction: .down, time: 10 + step)
        _ = engine.addBeat(beat(1, at: 10 + step))
        XCTAssertTrue(engine.addStrum(resent).isEmpty)
    }

    func test_events_comeOutInStepOrder() {
        var engine = makeEngine()
        var events = engine.addBeat(beat(0, at: 10))
        events += engine.addBeat(beat(2, at: 10 + 2 * step))
        events += engine.addStrum(PracticeFixtures.strum(at: 10 + 2 * step))
        XCTAssertEqual(events.map(\.stepIndex), [0, 2])
        XCTAssertEqual(events.map(\.result), [.miss, .perfect])
    }

    func test_latencyOffset_isAppliedWhenJudging() {
        var engine = makeEngine(offset: 0.1)
        _ = engine.addBeat(beat(0, at: 10))
        XCTAssertEqual(engine.addStrum(PracticeFixtures.strum(at: 10.1)).map(\.result), [.perfect])
    }

    func test_discardOpenBeats_returnsTheUnjudgedBeats() {
        var engine = makeEngine()
        _ = engine.addBeat(beat(3, at: 10))
        XCTAssertEqual(engine.discardOpenBeats().map(\.index), [3])
        XCTAssertTrue(engine.openBeats.isEmpty)
        XCTAssertTrue(engine.close(upTo: 20).isEmpty)
    }
}
