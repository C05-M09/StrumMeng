import XCTest
@testable import StrumMeng

/// Uses the actual Practice engine + FeedbackEngine with scripted host times and controller input.
@MainActor
final class SongEngineIntegrationTests: XCTestCase {
    private var now: TimeInterval = 100
    private func make(song: Song, link: MockControllerLink) -> PlayViewModel {
        PlayViewModel(pattern: SongTimeline(song: song).sessionPattern, bpm: song.bpm,
            clock: MockBeatClock(), input: link, touchInput: nil, controller: link,
            requiresController: true, leadInSteps: 0, repetitions: 1, finishBreak: 0,
            finishesAtDurationBoundary: true,
            now: { self.now }, waitUntil: { _ in try? await Task.sleep(for: .seconds(3600)) })
    }
    private func tick(_ engine: PlayViewModel, _ index: Int, interval: Double) {
        now = 100 + Double(index) * interval
        engine.handle(BeatTick(index: index, expectedTime: now))
    }
    func test_countInEntersPlayingOnFirstSongBeatAndJudgesTheCorrectNode() async {
        let song = DummySongCatalog().songs[0]; let timeline = SongTimeline(song: song)
        let engine = make(song: song, link: MockControllerLink())
        await engine.handle(.connected(latencyMs: 5))
        await engine.send(.tapReady)
        for index in 0..<6 { tick(engine, index, interval: timeline.slotInterval) }
        XCTAssertEqual(engine.state, .countIn(1))
        tick(engine, 6, interval: timeline.slotInterval)
        XCTAssertEqual(engine.state, .playing)
        XCTAssertEqual(engine.screenModel().songTime, 0, accuracy: 1e-9)
        engine.handle(PracticeFixtures.strum(at: now, .down))
        XCTAssertEqual(engine.beatEvents.first?.stepIndex, 0)
        XCTAssertEqual(engine.beatEvents.first?.result, .perfect)
        await engine.handle(.searching)
        XCTAssertEqual(engine.state, .disconnected)
        await engine.send(.tapResume)
        XCTAssertEqual(engine.state, .disconnected)
        await engine.handle(.connected(latencyMs: 5))
        await engine.send(.tapResume)
        XCTAssertEqual(engine.state, .countIn(3))
        await engine.onDisappear()
    }
    func test_lastPerfectDoesNotFinishBeforeFullSongDurationAndRestartDiscardsResults() async {
        let song = Song(id: "short", title: "Short", bpm: 80, patternID: "foundation",
            strokes: [.down], barCount: 1, chords: [SongChordChange(slot: 0, chord: "C")])
        let timeline = SongTimeline(song: song)
        let engine = make(song: song, link: MockControllerLink())
        await engine.handle(.connected(latencyMs: 5)); await engine.send(.tapReady)
        for index in 0..<6 { tick(engine, index, interval: timeline.slotInterval) }
        for slot in 0..<8 {
            tick(engine, slot + 6, interval: timeline.slotInterval)
            engine.handle(PracticeFixtures.strum(at: now, .down))
        }
        XCTAssertEqual(engine.state, .playing)
        tick(engine, 14, interval: timeline.slotInterval)
        guard case .finished = engine.state else { return XCTFail("Expected finished at end boundary") }
        XCTAssertEqual(engine.screenModel().songTime, timeline.duration, accuracy: 1e-9)
        await engine.send(.tapRestart)
        XCTAssertTrue(engine.beatEvents.isEmpty)
        await engine.onDisappear()
    }
    func test_strumsOutsideGameplayAreIgnored() async {
        let engine = make(song: DummySongCatalog().songs[0], link: MockControllerLink())
        engine.handle(PracticeFixtures.strum(at: now, .down))
        XCTAssertTrue(engine.beatEvents.isEmpty)
        await engine.handle(.connected(latencyMs: 5)); await engine.send(.tapReady)
        await engine.send(.tapPause)
        engine.handle(PracticeFixtures.strum(at: now, .down))
        XCTAssertTrue(engine.beatEvents.isEmpty)
        await engine.send(.tapBackToMenu)
        XCTAssertTrue(engine.beatEvents.isEmpty)
        await engine.onDisappear()
    }
}
