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

    // MARK: - Seek

    func test_seek_whilePlaying_schedulesFromTheNewPosition() {
        let viewModel = makeViewModel([])
        viewModel.send(.play)
        advance(viewModel, by: -viewModel.songTime() + 0.1)

        viewModel.send(.seek(progress: 1.5 / viewModel.duration))    // a click falls exactly at 1.5 s

        XCTAssertEqual(sound.clicks.last?.time ?? 0, hostClock, accuracy: 1e-9)
        XCTAssertGreaterThan(sound.stopStrumsCount, 0, "Strums from the old position are cut")
    }

    func test_seek_whilePaused_schedulesNothing_untilResume() {
        let viewModel = makeViewModel([])
        viewModel.send(.play)
        viewModel.send(.pause)
        let clicksBefore = sound.clicks.count

        viewModel.send(.seek(progress: 1.5 / viewModel.duration))
        viewModel.scheduleDueSounds()

        XCTAssertEqual(sound.clicks.count, clicksBefore)
    }

    // MARK: - Showtime

    private func makeShowtimeViewModel(strums: [RecordedStrum], track: MockSongBackingTrack) -> ReplayViewModel {
        let result = SessionResultBuilder.build(id: UUID(), patternID: "foundation", songID: "song", bpm: 80,
                                                beatEvents: [], strums: strums,
                                                createdAt: Date(timeIntervalSince1970: 0))
        // Steps 0-3 on G, steps 4-7 on D7.
        let chords: [GuitarChord] = Array(repeating: .named("G") ?? .c, count: 4)
            + Array(repeating: .named("D7") ?? .c, count: 4)
        return ReplayViewModel(result: result, repetitions: 1, guitar: sound, metronome: sound,
                               stepChords: chords, chordLabels: [0: "G", 4: "D7"], backingTrack: track,
                               now: { [unowned self] in self.songClock },
                               soundClock: { [unowned self] in self.hostClock })
    }

    func test_showtimeReplay_strumsTheChordOfTheirStep() {
        let track = MockSongBackingTrack()
        let viewModel = makeShowtimeViewModel(strums: [
            RecordedStrum(time: 0.01, direction: .down, isExtra: false),           // step 0: G
            RecordedStrum(time: 4 * step - 0.02, direction: .up, isExtra: false),  // nearest step 4: D7
        ], track: track)
        viewModel.send(.play)

        advance(viewModel, by: -viewModel.songTime() + 4 * step)

        XCTAssertEqual(sound.strums.map(\.chord), [GuitarChord.named("G"), GuitarChord.named("D7")])
    }

    func test_showtimeReplay_showsTheSongsChordLabels() {
        let viewModel = makeShowtimeViewModel(strums: [], track: MockSongBackingTrack())
        XCTAssertEqual(viewModel.screenModel().chordLabels, [0: "G", 4: "D7"])
    }

    func test_showtimeReplay_playsTheSongFromTheReplayPosition_andStopsItOnPause() {
        let track = MockSongBackingTrack()
        let viewModel = makeShowtimeViewModel(strums: [], track: track)
        viewModel.send(.play)
        XCTAssertEqual(track.plays.last?.songTime ?? 0, viewModel.songTime(), accuracy: 1e-9)
        XCTAssertEqual(track.plays.last?.hostTime, hostClock)

        songClock += 1; hostClock += 1
        viewModel.send(.pause)
        XCTAssertGreaterThan(track.stopCount, 0)

        let stops = track.stopCount
        viewModel.send(.resume)
        XCTAssertEqual(track.plays.count, 2)
        XCTAssertEqual(track.plays.last?.songTime ?? 0, viewModel.songTime(), accuracy: 1e-9)
        viewModel.send(.backToSummary)
        XCTAssertGreaterThan(track.stopCount, stops)
    }

    func test_practiceReplay_staysOnC_withoutSongOrLabels() {
        let viewModel = makeViewModel([BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0)])
        viewModel.send(.play)
        advance(viewModel, by: -viewModel.songTime() + 0.1)
        XCTAssertEqual(sound.strums.map(\.chord), [.c])
        XCTAssertTrue(viewModel.screenModel().chordLabels.isEmpty)
    }
}
