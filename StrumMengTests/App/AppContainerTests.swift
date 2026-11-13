//
//  AppContainerTests.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//

import XCTest
@testable import StrumMeng

@MainActor
final class AppContainerTests: XCTestCase {

    private var router: AppRouter!
    private var sut: AppContainer!

    override func setUp() {
        super.setUp()
        router = AppRouter()
        sut = AppContainer(router: router)
    }

    override func tearDown() {
        sut = nil
        router = nil
        super.tearDown()
    }

    // MARK: - Home

    func test_homeViewModel_tapPractice_pushesPracticeList() {
        let home = sut.makeHomeViewModel()

        home.send(.tapPractice)

        XCTAssertEqual(router.path.count, 1)
    }

    func test_homeViewModel_tapGuidebook_showsOverlayWithoutPushingRoute() {
        let home = sut.makeHomeViewModel()

        home.send(.tapGuidebook)

        XCTAssertEqual(router.path.count, 0, "Guidebook adalah overlay, bukan route")
        XCTAssertEqual(home.presentedOverlay, .guidebook)
    }

    func test_homeViewModel_tapOption_doesNotPushRoute() {
        let home = sut.makeHomeViewModel()

        home.send(.tapOption)

        XCTAssertEqual(router.path.count, 0, "Option adalah overlay, bukan route")
        XCTAssertEqual(home.presentedOverlay, .option)
    }

    func test_homeViewModel_tapShowtime_pushesShowtimeList() {
        let home = sut.makeHomeViewModel()

        home.send(.tapShowtime)

        XCTAssertEqual(router.path, [.showtimeList])
        XCTAssertNil(home.presentedOverlay)
    }

    // MARK: - Option

    func test_optionViewModel_tapBack_callsInjectedAction() {
        var backCount = 0
        let option = sut.makeOptionViewModel { backCount += 1 }

        option.send(.tapBack)

        XCTAssertEqual(backCount, 1)
    }

    func test_optionViewModel_tapBack_doesNotPopRouter() {
        router.push(.practiceList)
        let option = sut.makeOptionViewModel {}

        option.send(.tapBack)

        XCTAssertEqual(router.path.count, 1, "Back di Option menutup overlay, tidak men-pop router")
    }

    func test_optionOverlay_closesThroughHomeViewModel() {
        // Meniru penyambungan di ContentView
        let home = sut.makeHomeViewModel()
        let option = sut.makeOptionViewModel { [weak home] in
            home?.send(.dismissOverlay)
        }
        home.send(.tapOption)
        XCTAssertEqual(home.presentedOverlay, .option)

        option.send(.tapBack)

        XCTAssertNil(home.presentedOverlay)
    }

    // MARK: - Menu sounds

    /// A store in its own suite, so these tests never touch the real saved volumes.
    private func makeIsolatedSettings() -> (UserDefaultsSettingsStore, String) {
        let suiteName = "container-sound-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        return (UserDefaultsSettingsStore(defaults: defaults), suiteName)
    }

    func test_init_appliesTheSavedVolumesToTheMenuSounds() {
        let (settings, suiteName) = makeIsolatedSettings()
        defer { UserDefaults().removePersistentDomain(forName: suiteName) }
        settings.setSoundVolume(0.2)
        settings.setSFXVolume(0.9)
        let sounds = MockMenuSoundService()

        _ = AppContainer(router: router, settings: settings, menuSounds: sounds)

        XCTAssertEqual(sounds.musicVolumes, [0.2])
        XCTAssertEqual(sounds.effectsVolumes, [0.9])
    }

    func test_optionSliders_reachTheSharedMenuSounds() {
        let (settings, suiteName) = makeIsolatedSettings()
        defer { UserDefaults().removePersistentDomain(forName: suiteName) }
        let sounds = MockMenuSoundService()
        let container = AppContainer(router: router, settings: settings, menuSounds: sounds)
        let option = container.makeOptionViewModel {}

        option.send(.changeSoundVolume(0.6))
        option.send(.changeSFXVolume(0.1))

        XCTAssertEqual(sounds.musicVolumes.last, 0.6)
        XCTAssertEqual(sounds.effectsVolumes.last, 0.1)
    }

    func test_updateMenuMusic_onHome_startsTheMusic() {
        let sounds = MockMenuSoundService()
        let container = AppContainer(router: router, menuSounds: sounds)

        container.updateMenuMusic(for: [], isAppActive: true)

        XCTAssertEqual(sounds.startMusicCount, 1)
        XCTAssertEqual(sounds.pauseMusicCount, 0)
    }

    func test_updateMenuMusic_onListen_pausesTheMusic() {
        let sounds = MockMenuSoundService()
        let container = AppContainer(router: router, menuSounds: sounds)

        container.updateMenuMusic(
            for: [.practiceList, .listen(patternID: "p", bpm: 80)],
            isAppActive: true
        )

        XCTAssertEqual(sounds.pauseMusicCount, 1)
        XCTAssertEqual(sounds.startMusicCount, 0)
    }

    func test_updateMenuMusic_whenAppIsInactive_pausesTheMusic() {
        let sounds = MockMenuSoundService()
        let container = AppContainer(router: router, menuSounds: sounds)

        container.updateMenuMusic(for: [], isAppActive: false)

        XCTAssertEqual(sounds.pauseMusicCount, 1)
        XCTAssertEqual(sounds.startMusicCount, 0)
    }
    // MARK: - Practice session flow

    private func finishedSession(bpm: Int = 80) -> SessionResult {
        SessionResultBuilder.build(id: UUID(), patternID: "foundation", bpm: bpm,
                                   beatEvents: PracticeFixtures.events([.perfect, .miss, .tooEarly, .miss]),
                                   createdAt: Date())
    }

    /// Summary navigates once the session is saved, which takes a moment on the in-memory store.
    private func waitForPath(_ expected: [AppRoute], on router: AppRouter) async throws {
        for _ in 0..<200 where router.path != expected {
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTAssertEqual(router.path, expected)
    }

    /// Waits until the stack is the practice list with a Listen on top, and returns that Listen.
    private func waitForListen(on router: AppRouter) async throws -> AppRoute? {
        for _ in 0..<200 {
            if router.path.count == 2, router.path.first == .practiceList,
               case .listen = router.path.last {
                return router.path.last
            }
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("Expected [practiceList, listen], got \(router.path)")
        return nil
    }

    func test_finishedSession_replacesPlayWithSummary() {
        let container = AppContainer(router: router, inMemory: true)
        let listen = AppRoute.listen(patternID: "foundation", bpm: 80)
        router.path = [.practiceList, listen, .play(patternID: "foundation", bpm: 80)]
        let session = finishedSession()

        container.sessionFinished(session)

        XCTAssertEqual(router.path, [.practiceList, listen, .summary(sessionID: session.id)])
        XCTAssertEqual(container.makeSummaryViewModel(sessionID: session.id)?.result, session)
    }

    func test_summaryForAnUnknownSession_isNil() {
        let container = AppContainer(router: router, inMemory: true)

        XCTAssertNil(container.makeSummaryViewModel(sessionID: UUID()))
    }

    func test_retry_listensAgainAtTheChosenTempo_andTheListKeepsIt() async throws {
        let container = AppContainer(router: router, inMemory: true)
        let list = container.makePatternListViewModel()
        let session = finishedSession(bpm: 80)
        router.path = [.practiceList, .listen(patternID: "foundation", bpm: 80), .play(patternID: "foundation", bpm: 80)]
        container.sessionFinished(session)
        let summary = try XCTUnwrap(container.makeSummaryViewModel(sessionID: session.id))

        summary.send(.tapRetry)
        guard case let .showingRecommendation(recommendation) = summary.state else {
            return XCTFail("Retry should show the BPM recommendation first")
        }
        summary.send(.acceptRecommendation)

        let route = try await waitForListen(on: router)
        guard case let .listen(patternID, bpm, _) = route else { return }
        XCTAssertEqual(patternID, "foundation")
        XCTAssertEqual(bpm, recommendation.targetBPM)
        XCTAssertEqual(list.state.selectedBPM, recommendation.targetBPM)
    }

    /// Regression: keeping the same tempo used to show the old, finished Listen screen (frozen).
    func test_retryAtTheSameTempo_opensANewListenScreen() async throws {
        let container = AppContainer(router: router, inMemory: true)
        let session = finishedSession(bpm: 75)
        let firstListen = AppRoute.listen(patternID: "foundation", bpm: 75)
        router.path = [.practiceList, firstListen, .play(patternID: "foundation", bpm: 75)]
        container.sessionFinished(session)
        let summary = try XCTUnwrap(container.makeSummaryViewModel(sessionID: session.id))

        summary.send(.tapRetry)
        summary.send(.rejectRecommendation)

        let route = try await waitForListen(on: router)
        XCTAssertNotEqual(route, firstListen, "Must be a new screen, not the one already used")
        guard case let .listen(patternID, bpm, _) = route else { return }
        XCTAssertEqual(patternID, "foundation")
        XCTAssertEqual(bpm, 75)
    }

    func test_backToMain_returnsToThePracticeList() async throws {
        let container = AppContainer(router: router, inMemory: true)
        let session = finishedSession()
        router.path = [.practiceList, .listen(patternID: "foundation", bpm: 80), .play(patternID: "foundation", bpm: 80)]
        container.sessionFinished(session)
        let summary = try XCTUnwrap(container.makeSummaryViewModel(sessionID: session.id))

        summary.send(.tapBackToMain)

        try await waitForPath([.practiceList], on: router)
    }

    func test_backOnListen_returnsToThePracticeList() {
        let container = AppContainer(router: router, inMemory: true)
        let pattern = PatternCatalog.foundation
        router.path = [.practiceList, .listen(patternID: pattern.id, bpm: 80)]
        let listen = container.makeListenViewModel(pattern: pattern, bpm: 80)

        listen.send(.back)

        XCTAssertEqual(router.path, [.practiceList])
    }

    // MARK: - Guidebook

    func test_guidebookViewModel_dismiss_callsInjectedAction() {
        var backCount = 0
        let guidebook = sut.makeGuidebookViewModel { backCount += 1 }

        guidebook.dismiss()

        XCTAssertEqual(backCount, 1)
    }

    func test_guidebookOverlay_closesThroughHomeViewModel() {
        let home = sut.makeHomeViewModel()
        let guidebook = sut.makeGuidebookViewModel { [weak home] in
            home?.send(.dismissOverlay)
        }
        home.send(.tapGuidebook)
        XCTAssertEqual(home.presentedOverlay, .guidebook)

        guidebook.dismiss()

        XCTAssertNil(home.presentedOverlay)
    }
    func test_songCardOpensSessionAndBackReturnsToShowtimeList() async throws {
        let router = AppRouter()
        let container = AppContainer(router: router, inMemory: true,
            menuSounds: MockMenuSoundService(), controllerLink: MockControllerLink())
        container.makeHomeViewModel().send(.tapShowtime)
        let list = container.makeSongListViewModel()
        list.select(list.songs[0].id)
        guard case .showtime(let id, _) = router.path.last else { return XCTFail("Expected song route") }
        let session = try XCTUnwrap(container.makeShowtimeViewModel(songID: id))
        XCTAssertEqual(session.state, .intro)
        await session.send(.back)
        XCTAssertEqual(router.path, [.showtimeList])
        XCTAssertNil(container.makeShowtimeViewModel(songID: "unknown-song"))
    }

    func test_showtimeReplay_isBuiltForTheSongOfTheResult() throws {
        let container = AppContainer(router: AppRouter(), inMemory: true,
            menuSounds: MockMenuSoundService(), controllerLink: MockControllerLink())
        let song = try XCTUnwrap(container.makeSongListViewModel().songs.first)
        func result(songID: String?) -> SessionResult {
            SessionResult(id: UUID(), patternID: song.patternID, songID: songID, bpm: song.bpm, accuracy: 1,
                          perfectCount: 0, tooEarlyCount: 0, missCount: 0, createdAt: Date(), beatEvents: [])
        }
        let replay = try XCTUnwrap(container.makeShowtimeReplayViewModel(result: result(songID: song.id)))
        XCTAssertEqual(replay.totalSteps, SongTimeline(song: song).totalSlots)
        XCTAssertEqual(replay.screenModel().chordLabels, SongTimeline(song: song).chordLabels)
        XCTAssertEqual(replay.screenModel().title, song.title)
        XCTAssertNil(container.makeShowtimeReplayViewModel(result: result(songID: "unknown-song")))
        XCTAssertNil(container.makeShowtimeReplayViewModel(result: result(songID: nil)))
    }

}
