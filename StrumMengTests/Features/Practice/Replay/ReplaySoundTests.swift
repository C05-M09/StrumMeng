import XCTest
@testable import StrumMeng

/// Replay's sound: the metronome and the player's recorded strums, scheduled on the host clock.
@MainActor
final class ReplaySoundTests: XCTestCase {
    private var songClock: TimeInterval = 100
    private var hostClock: TimeInterval = 5000
    private var sound: MockGuitarSound!
    private let step = 0.375

    override func setUp() {
        super.setUp()
        songClock = 100
        hostClock = 5000
        sound = MockGuitarSound()
    }

    private func makeViewModel(_ events: [BeatEvent]) -> ReplayViewModel {
        let result = SessionResultBuilder.build(id: UUID(), patternID: "foundation", bpm: 80,
                                                beatEvents: events, createdAt: Date(timeIntervalSince1970: 0))
        return ReplayViewModel(result: result, repetitions: 1, guitar: sound, metronome: sound,
                               now: { [unowned self] in self.songClock },
                               soundClock: { [unowned self] in self.hostClock })
    }

    /// Moves both clocks on together and lets the replay schedule what is due.
    private func advance(_ viewModel: ReplayViewModel, by seconds: TimeInterval) {
        songClock += seconds
        hostClock += seconds
        viewModel.scheduleDueSounds()
    }

    func test_nothingSounds_beforePlay() {
        let viewModel = makeViewModel([BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0)])

        viewModel.scheduleDueSounds()

        XCTAssertTrue(sound.strums.isEmpty)
        XCTAssertTrue(sound.clicks.isEmpty)
    }

    func test_play_schedulesTheFirstBeat_onTheHostClock() {
        let viewModel = makeViewModel([BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 10)])
        viewModel.send(.play)
        let lead = -viewModel.songTime()                              // song time starts before step 0

        advance(viewModel, by: lead - 0.05)                           // step 0 is now 50 ms away

        XCTAssertEqual(sound.clicks.first?.time ?? 0, hostClock + 0.05, accuracy: 1e-9)
        XCTAssertEqual(sound.clicks.first?.accent, true)
        XCTAssertEqual(sound.strums.first?.direction, .down)
        XCTAssertEqual(sound.strums.first?.time ?? 0, hostClock + 0.06, accuracy: 1e-9)
    }

    func test_soundsAreOnlyScheduledWithinTheLookahead() {
        let viewModel = makeViewModel([])
        viewModel.send(.play)

        advance(viewModel, by: -viewModel.songTime() + 1)            // song time 1 s

        let latest = sound.clicks.map(\.time).max() ?? 0
        XCTAssertLessThan(latest, hostClock + ReplayViewModel.soundLookahead)
        XCTAssertEqual(sound.clicks.count, 2, "Clicks at 0 and 0.75 s; the one at 1.5 s is not due yet")
    }

    func test_pause_silences_andResumeContinuesWithoutRepeating() {
        let viewModel = makeViewModel([])
        viewModel.send(.play)
        advance(viewModel, by: -viewModel.songTime() + 0.8)          // clicks at 0 and 0.75 scheduled
        let beforePause = sound.clicks.count

        viewModel.send(.pause)
        XCTAssertGreaterThan(sound.cancelClicksCount, 0)
        XCTAssertGreaterThan(sound.stopStrumsCount, 0)

        hostClock += 10                                               // time passes while paused
        viewModel.send(.resume)
        advance(viewModel, by: 0.7)                                   // song time 1.5 s

        XCTAssertEqual(sound.clicks.count, beforePause + 1, "Only the click at 1.5 s is new")
    }

    func test_backToSummary_silences() {
        let viewModel = makeViewModel([])
        viewModel.send(.play)

        viewModel.send(.backToSummary)

        XCTAssertGreaterThan(sound.stopStrumsCount, 0)
        XCTAssertGreaterThan(sound.cancelClicksCount, 0)
    }
}
