import XCTest
@testable import StrumMeng

@MainActor
final class SynthListenPlayerTests: XCTestCase {
    private var clock: TimeInterval = 100
    private var sound: MockGuitarSound!
    private var player: SynthListenPlayer!

    /// Foundation at 80 BPM: down on every quarter note, an eighth note = 0.375 s.
    private let pattern = PatternCatalog.foundation
    private let step = 0.375

    override func setUp() {
        super.setUp()
        clock = 100
        sound = MockGuitarSound()
        player = SynthListenPlayer(sound: sound, now: { [unowned self] in self.clock })
    }

    private func advance(to time: TimeInterval) {
        clock = time
        player.scheduleDue()
    }

    /// The clock time at which the strum at `time` is handed to the engine.
    private func dueTime(of time: TimeInterval) -> TimeInterval {
        time - SynthListenPlayer.lookahead + 0.001
    }

    func test_start_schedulesTheFirstStrumJustAhead() throws {
        try player.start(pattern: pattern, bpm: 80)
        XCTAssertTrue(sound.strums.isEmpty, "Not due yet: it starts further ahead than the lookahead")

        advance(to: dueTime(of: 100 + SynthListenPlayer.startLead))

        XCTAssertEqual(sound.strums, [.init(direction: .down, time: 100 + SynthListenPlayer.startLead, accent: 1)])
    }

    func test_strums_followThePattern_onTheEighthNoteGrid_andSkipRests() throws {
        try player.start(pattern: PatternCatalog.all[1], bpm: 80)    // down up down up …
        let first = 100 + SynthListenPlayer.startLead

        advance(to: dueTime(of: first + 4 * step))

        XCTAssertEqual(sound.strums.map(\.direction), [.down, .up, .down, .up, .down])
        for (index, strum) in sound.strums.enumerated() {
            XCTAssertEqual(strum.time ?? 0, first + Double(index) * step, accuracy: 1e-9)
        }
    }

    func test_rests_makeNoStrum() throws {
        try player.start(pattern: pattern, bpm: 80)                  // down rest down rest …
        let first = 100 + SynthListenPlayer.startLead

        advance(to: dueTime(of: first + 4 * step))

        XCTAssertEqual(sound.strums.compactMap(\.time).map { (($0 - first) / step).rounded() }, [0, 2, 4])
    }

    func test_strumsAreOnlyScheduledWithinTheLookahead() throws {
        try player.start(pattern: PatternCatalog.all[1], bpm: 80)

        advance(to: 105)

        let latest = sound.strums.compactMap(\.time).max() ?? 0
        XCTAssertLessThan(latest, 105 + SynthListenPlayer.lookahead)
    }

    func test_patternLoops() throws {
        try player.start(pattern: PatternCatalog.all[1], bpm: 80)
        let first = 100 + SynthListenPlayer.startLead

        advance(to: dueTime(of: first + 8 * step))

        XCTAssertEqual(sound.strums.count, 9, "Step 8 is the first step of the second loop")
        XCTAssertEqual(sound.strums.last?.direction, .down)
    }

    func test_elapsed_countsFromTheFirstStrum() throws {
        try player.start(pattern: pattern, bpm: 80)

        XCTAssertEqual(player.elapsed, 0)
        clock = 100 + SynthListenPlayer.startLead + 1.5
        XCTAssertEqual(player.elapsed, 1.5, accuracy: 1e-9)
    }

    func test_pause_freezesElapsed_silences_andSchedulesNothing() throws {
        try player.start(pattern: pattern, bpm: 80)
        clock = 100 + SynthListenPlayer.startLead + 1
        player.pause()
        let strumsAtPause = sound.strums.count

        advance(to: 110)

        XCTAssertEqual(player.elapsed, 1, accuracy: 1e-9)
        XCTAssertGreaterThan(sound.stopStrumsCount, 0)
        XCTAssertEqual(sound.strums.count, strumsAtPause)
    }

    func test_resume_continuesWithTheNextStep() throws {
        try player.start(pattern: PatternCatalog.all[1], bpm: 80)
        let first = 100 + SynthListenPlayer.startLead
        // Steps 0…2 have sounded; step 3 (at 1.125 s) was scheduled, but pausing drops it.
        advance(to: first + 1.1)
        player.pause()
        let beforeResume = sound.strums.count

        clock = 200
        player.resume()
        let expected = 200 + SynthListenPlayer.startLead + (3 * step - 1.1)
        advance(to: dueTime(of: expected))

        XCTAssertEqual(sound.strums.count, beforeResume + 1)
        XCTAssertEqual(sound.strums.last?.time ?? 0, expected, accuracy: 1e-9)
        XCTAssertEqual(sound.strums.last?.direction, .up, "Step 3 is an up, played again after the pause")
    }

    func test_stop_silences_andResetsElapsed() throws {
        try player.start(pattern: pattern, bpm: 80)
        clock = 102

        player.stop()

        XCTAssertEqual(player.elapsed, 0)
        XCTAssertGreaterThan(sound.stopStrumsCount, 0)
    }

    func test_invalidTempo_throws() {
        XCTAssertThrowsError(try player.start(pattern: pattern, bpm: 0))
    }
}
