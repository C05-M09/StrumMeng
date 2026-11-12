import XCTest
@testable import StrumMeng

/// The Showtime additions to the shared game loop: a chord per step, and the song's recording
/// following the count-in, pause, restart and leaving.
@MainActor
final class PlayViewModelSongTests: XCTestCase {
    private let start: TimeInterval = 100
    private let step = AudioBeatClock.stepInterval(bpm: 80)    // 0.375 s
    private var currentTime: TimeInterval = 0
    private let clock = MockBeatClock()
    private let sound = MockGuitarSound()
    private let backing = MockSongBackingTrack()

    /// Two bars of down strokes: C for the first bar, G for the second.
    private let song = StrumPattern(id: "song", name: "Song", strokes: Array(repeating: .down, count: 16),
                                    beatLabels: [], beatsPerPattern: 8, suggestedOrder: 1, defaultBPM: 80)
    private let chords = Array(repeating: GuitarChord.c, count: 8) + Array(repeating: GuitarChord.g, count: 8)

    private func makeViewModel(stepChords: [GuitarChord]? = nil, leadInSteps: Int = 0,
                               withBacking: Bool = true) -> PlayViewModel {
        PlayViewModel(
            pattern: song, bpm: 80, songID: "twinkle-twinkle", clock: clock, input: MockStrumInputService(),
            touchInput: nil, requiresController: false, guitar: sound, metronome: sound,
            leadInSteps: leadInSteps, repetitions: 1, finishBreak: 0, finishesAtDurationBoundary: true,
            stepChords: stepChords ?? chords, backingTrack: withBacking ? backing : nil,
            now: { [unowned self] in self.currentTime },
            waitUntil: { _ in try? await Task.sleep(for: .seconds(3600)) })
    }

    /// Clock tick n: 0...5 are the count-in (with no lead-in), tick 6 is step 0.
    private func time(ofTick n: Int) -> TimeInterval { start + Double(n) * step }

    private func tick(_ viewModel: PlayViewModel, _ n: Int) {
        currentTime = time(ofTick: n)
        viewModel.handle(BeatTick(index: n, expectedTime: currentTime))
    }

    private func startPlaying(_ viewModel: PlayViewModel) async {
        await viewModel.send(.tapReady)
        for n in 0...6 { tick(viewModel, n) }
    }

    private func strum(_ viewModel: PlayViewModel, at time: TimeInterval) {
        currentTime = max(currentTime, time)
        viewModel.handle(PracticeFixtures.strum(at: time))
    }

    // MARK: Chords

    func test_strum_playsTheChordAtItsPlaceInTheSong() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6 + 2))
        strum(viewModel, at: time(ofTick: 6 + 9))
        XCTAssertEqual(sound.strums.map(\.chord), [.c, .g])
    }

    func test_strumJustBeforeAChordChange_playsTheNewChord() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6 + 8) - 0.05)
        XCTAssertEqual(sound.strums.map(\.chord), [.g])
    }

    func test_strumBeforeTheSessionStarts_playsTheFirstChord() {
        let viewModel = makeViewModel()
        strum(viewModel, at: 1)
        XCTAssertEqual(sound.strums.map(\.chord), [.c])
    }

    func test_strumAfterTheLastStep_playsTheLastChord() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6 + 40))
        XCTAssertEqual(sound.strums.map(\.chord), [.g])
    }

    func test_strumWhilePaused_playsTheChordWhereTheSongStopped() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        for n in 7...16 { tick(viewModel, n) }
        await viewModel.send(.tapPause)
        strum(viewModel, at: currentTime + 5)
        XCTAssertEqual(sound.strums.map(\.chord), [.g])
    }

    func test_withoutStepChords_everyStrumPlaysC_asInPractice() async {
        let viewModel = makeViewModel(stepChords: [])
        await startPlaying(viewModel)
        strum(viewModel, at: time(ofTick: 6 + 9))
        XCTAssertEqual(sound.strums.map(\.chord), [.c])
    }

    func test_onAppear_preparesEachSongChordOnce_andTheRecording() async {
        let viewModel = makeViewModel()
        viewModel.onAppear()
        for _ in 0..<20 where sound.preparedChords.isEmpty { await Task.yield() }
        XCTAssertEqual(sound.preparedChords, [[.c, .g]])
        XCTAssertEqual(backing.preparedSongIDs, ["twinkle-twinkle"])
        await viewModel.onDisappear()
    }

    // MARK: Recording

    func test_countIn_startsTheRecordingSoTheFirstNodeLandsOnItsFirstBeat() async {
        let viewModel = makeViewModel(leadInSteps: 2)
        await viewModel.send(.tapReady)
        tick(viewModel, 0)
        // The count-in ends after 6 steps, at the start of the 2-step lead-in.
        XCTAssertEqual(backing.plays, [.init(songTime: -2 * step, hostTime: time(ofTick: 6))])
        for n in 1...8 { tick(viewModel, n) }
        XCTAssertEqual(backing.plays.count, 1, "Started once per count-in")
        XCTAssertEqual(viewModel.screenModel().songTime, 0, accuracy: 1e-9, "Step 0 at tick 6 + 2")
    }

    func test_pause_stopsTheRecording_andResumeContinuesWhereItPaused() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        tick(viewModel, 8)
        currentTime = time(ofTick: 8) + 0.1
        let stopsBefore = backing.stopCount
        await viewModel.send(.tapPause)
        XCTAssertEqual(backing.stopCount, stopsBefore + 1)

        await viewModel.send(.tapResume)
        tick(viewModel, 20)
        XCTAssertEqual(backing.plays.last?.songTime ?? -1, 2 * step + 0.1, accuracy: 1e-9)
        XCTAssertEqual(backing.plays.last?.hostTime ?? -1, time(ofTick: 26), accuracy: 1e-9)
    }

    func test_restartAndBackToMenu_stopTheRecording() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        await viewModel.send(.tapPause)
        let stops = backing.stopCount
        await viewModel.send(.tapRestart)
        XCTAssertGreaterThan(backing.stopCount, stops)
        await viewModel.send(.tapPause)
        let stopsBeforeBack = backing.stopCount
        await viewModel.send(.tapBackToMenu)
        XCTAssertGreaterThan(backing.stopCount, stopsBeforeBack)
    }

    func test_finish_letsTheRecordingPlayOn() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        let stops = backing.stopCount
        for n in 7...22 { tick(viewModel, n) }
        viewModel.closeWindows(upTo: time(ofTick: 22) + 1)
        guard case .finished = viewModel.state else { return XCTFail("Expected finished, got \(viewModel.state)") }
        XCTAssertEqual(backing.stopCount, stops, "The song is not cut when the last node passes")
    }

    func test_leaving_stopsTheRecording() async {
        let viewModel = makeViewModel()
        await startPlaying(viewModel)
        let stops = backing.stopCount
        await viewModel.onDisappear()
        XCTAssertGreaterThan(backing.stopCount, stops)
    }

    func test_withoutRecording_theSessionPlaysAsBefore() async {
        let viewModel = makeViewModel(withBacking: false)
        await startPlaying(viewModel)
        XCTAssertEqual(viewModel.state, .playing)
        XCTAssertTrue(backing.plays.isEmpty)
    }
}
