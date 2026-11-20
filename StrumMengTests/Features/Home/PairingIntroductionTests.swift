import XCTest
@testable import StrumMeng

@MainActor
final class PairingIntroductionTests: XCTestCase {
    func test_reducerWaitsThenWelcomesAndFinishes() {
        var state = PairingIntroductionState.idle
        state = reduce(state, .begin)
        XCTAssertEqual(state, .waiting)
        XCTAssertTrue(state.blocksHome)
        state = reduce(state, .delayElapsed)
        XCTAssertEqual(state, .welcoming)
        state = reduce(state, .continueToSetup)
        XCTAssertEqual(state, .finished)
        XCTAssertFalse(state.blocksHome)
    }

    func test_illegalEventsCannotSkipTheWelcomeOrRepeatIt() {
        XCTAssertEqual(reduce(PairingIntroductionState.idle, .continueToSetup), .idle)
        XCTAssertEqual(reduce(PairingIntroductionState.waiting, .continueToSetup), .waiting)
        XCTAssertEqual(reduce(PairingIntroductionState.finished, .begin), .finished)
        XCTAssertEqual(reduce(PairingIntroductionState.welcoming, .cancel), .idle)
    }

    func test_nextSavesTheFlagAndOpensSetupOnlyOnce() {
        let store = IntroductionStore()
        var routes = 0
        let model = PairingIntroductionViewModel(store: store, onSetupRequested: { routes += 1 })
        defer { model.setActive(false) }
        model.setActive(true)
        XCTAssertEqual(model.state, .waiting)
        XCTAssertFalse(store.hasShownIntroduction)
        model.send(.delayElapsed)
        model.send(.continueToSetup)
        model.send(.continueToSetup)
        model.setActive(true)
        XCTAssertEqual(routes, 1)
        XCTAssertTrue(store.hasShownIntroduction)
        XCTAssertEqual(model.state, .finished)
    }

    func test_returningPlayerIsNotPrompted() {
        let store = IntroductionStore()
        store.markIntroductionShown()
        let model = PairingIntroductionViewModel(store: store, onSetupRequested: {
            XCTFail("Returning players must not be redirected")
        })
        model.setActive(true)
        XCTAssertEqual(model.state, .finished)
    }

    func test_welcomeWaitsForNextWithoutAutomaticallyNavigating() async {
        let store = IntroductionStore()
        let delayElapsed = expectation(description: "Appearance delay completed")
        var waits: [Duration] = []
        var routes = 0
        let model = PairingIntroductionViewModel(store: store, wait: { delay in
            waits.append(delay)
            await Task.yield()
            delayElapsed.fulfill()
        }, onSetupRequested: { routes += 1 })
        defer { model.setActive(false) }
        model.setActive(true)
        await fulfillment(of: [delayElapsed], timeout: 1)
        for _ in 0..<5 { await Task.yield() }
        XCTAssertEqual(waits, [.milliseconds(1500)], "Only the initial appearance uses a delay")
        XCTAssertEqual(model.state, .welcoming)
        XCTAssertEqual(routes, 0)
        XCTAssertFalse(store.hasShownIntroduction)

        model.send(.continueToSetup)
        XCTAssertEqual(routes, 1)
        XCTAssertTrue(store.hasShownIntroduction)
        XCTAssertEqual(model.state, .finished)
    }

    func test_backgroundingCancelsPresentationWithoutConsumingFirstLaunch() async {
        let store = IntroductionStore()
        let model = PairingIntroductionViewModel(store: store, onSetupRequested: {
            XCTFail("An inactive Home must not redirect")
        })
        defer { model.setActive(false) }
        model.setActive(true)
        model.send(.delayElapsed)
        model.setActive(false)
        await Task.yield()
        XCTAssertEqual(model.state, .idle)
        XCTAssertFalse(store.hasShownIntroduction)
        model.setActive(true)
        XCTAssertEqual(model.state, .waiting)
    }

    func test_previewStateDoesNotPresentOrPersist() {
        let store = IntroductionStore()
        let model = PairingIntroductionViewModel(store: store, state: .finished,
                                                onSetupRequested: { XCTFail("Preview must not navigate") })
        model.setActive(true)
        XCTAssertFalse(store.hasShownIntroduction)
        XCTAssertEqual(model.state, .finished)
    }

    func test_flagPersistsAcrossStoreInstances() throws {
        let suite = "PairingIntroductionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = UserDefaultsPairingIntroductionStore(defaults: defaults)
        XCTAssertFalse(first.hasShownIntroduction)
        first.markIntroductionShown()
        let next = UserDefaultsPairingIntroductionStore(defaults: defaults)
        XCTAssertTrue(next.hasShownIntroduction)
    }
}

@MainActor
private final class IntroductionStore: PairingIntroductionStore {
    private(set) var hasShownIntroduction = false
    func markIntroductionShown() { hasShownIntroduction = true }
}
