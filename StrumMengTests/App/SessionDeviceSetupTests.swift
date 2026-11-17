import XCTest
@testable import StrumMeng

@MainActor
final class SessionDeviceSetupTests: XCTestCase {
    func test_recoveryBackPreservesTheExactPracticeRouteAndPausedProgress() async throws {
        let router = AppRouter()
        let container = AppContainer(router: router, inMemory: true,
            menuSounds: MockMenuSoundService(), controllerLink: MockControllerLink())
        router.path = [.practiceList, .play(patternID: "foundation", bpm: 80)]
        let originalPath = router.path
        let game = container.makePlayViewModel(pattern: PatternCatalog.foundation, bpm: 80)
        await game.handle(.connected(latencyMs: 5))
        await game.send(.tapReady)
        for index in 0...10 { game.handle(BeatTick(index: index, expectedTime: 100 + Double(index) * 0.375)) }
        await game.handle(.reconnecting)
        XCTAssertEqual(game.state, .disconnected)
        let progress = game.screenModel().songTime
        game.requestDeviceSetup()
        XCTAssertTrue(router.isSessionDeviceSetupPresented)
        XCTAssertEqual(router.path, originalPath)
        let setup = container.makeDeviceSetupViewModel(isSessionRecovery: true)
        setup.send(.tapBack)
        XCTAssertFalse(router.isSessionDeviceSetupPresented)
        XCTAssertEqual(router.path, originalPath)
        XCTAssertEqual(game.state, .disconnected)
        XCTAssertEqual(game.screenModel().songTime, progress)
        await game.send(.tapResume)
        XCTAssertEqual(game.state, .disconnected, "Resume must wait for an actual connection")
        await game.handle(.connected(latencyMs: 5))
        XCTAssertEqual(game.state, .disconnected, "Pairing does not resume automatically")
        await game.send(.tapResume)
        XCTAssertEqual(game.state, .countIn(3))
        await game.onDisappear()
    }

    func test_doneAfterPairingDismissesRecoveryWithoutPoppingShowtimeRoute() {
        let router = AppRouter()
        let container = AppContainer(router: router, inMemory: true,
            menuSounds: MockMenuSoundService(), controllerLink: MockControllerLink())
        router.path = [.showtimeList, .showtime(songID: "twinkle-twinkle")]
        let path = router.path
        router.presentSessionDeviceSetup()
        let setup = container.makeDeviceSetupViewModel(isSessionRecovery: true)
        setup.send(.tapDone)
        XCTAssertTrue(router.isSessionDeviceSetupPresented)
        setup.send(.linkStateChanged(.connected(latencyMs: 4)))
        setup.send(.tapDone)
        XCTAssertFalse(router.isSessionDeviceSetupPresented)
        XCTAssertEqual(router.path, path)
    }

    func test_requestWhileNotDisconnectedDoesNotOpenSetup() {
        let router = AppRouter()
        let container = AppContainer(router: router, inMemory: true,
            menuSounds: MockMenuSoundService(), controllerLink: MockControllerLink())
        let game = container.makePlayViewModel(pattern: PatternCatalog.foundation, bpm: 80)
        game.requestDeviceSetup()
        XCTAssertFalse(router.isSessionDeviceSetupPresented)
    }
}
