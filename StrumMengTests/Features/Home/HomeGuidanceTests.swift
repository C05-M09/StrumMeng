import XCTest
@testable import StrumMeng

@MainActor
final class HomeGuidanceTests: XCTestCase {
    func test_homeWithoutSuccessfulPairingShowsNoGuidance() {
        let model = HomeGuidanceViewModel(store: GuidanceStore())
        model.send(.homeAppeared)
        XCTAssertEqual(model.state, .dormant)
        model.send(.advance)
        XCTAssertEqual(model.state, .dormant)
    }

    func test_optionThenGuidebookAdvanceOnTapsAndPersistCompletion() {
        let store = GuidanceStore()
        store.scheduleAfterPairing()
        let model = HomeGuidanceViewModel(store: store)
        model.send(.homeAppeared)
        XCTAssertEqual(model.state, .option)
        model.send(.advance)
        XCTAssertEqual(model.state, .guidebook)
        XCTAssertFalse(store.hasCompleted)
        model.send(.advance)
        XCTAssertEqual(model.state, .finished)
        XCTAssertTrue(store.hasCompleted)
        XCTAssertFalse(store.isPending)
        model.send(.homeAppeared)
        model.send(.advance)
        XCTAssertEqual(model.state, .finished)
    }

    func test_unfinishedTourStartsAgainOnNextLaunch() {
        let store = GuidanceStore()
        store.scheduleAfterPairing()
        let first = HomeGuidanceViewModel(store: store)
        first.send(.homeAppeared)
        first.send(.advance)
        let next = HomeGuidanceViewModel(store: store)
        next.send(.homeAppeared)
        XCTAssertEqual(next.state, .option)
    }

    func test_repeatedHomeAppearanceKeepsTheCurrentTip() {
        let store = GuidanceStore()
        store.scheduleAfterPairing()
        let model = HomeGuidanceViewModel(store: store)
        model.send(.homeAppeared)
        model.send(.advance)
        model.send(.homeAppeared)
        XCTAssertEqual(model.state, .guidebook)
    }

    func test_connectedDoneSchedulesGuidanceBeforeHomeIsOpened() {
        let store = GuidanceStore()
        let guidance = HomeGuidanceViewModel(store: store)
        let setup = DeviceSetupViewModel(link: MockControllerLink(), state: .connected(latencyMs: 5),
            onClose: { guidance.send(.homeAppeared) },
            onPairedDone: { store.scheduleAfterPairing() })
        setup.send(.tapDone)
        XCTAssertEqual(guidance.state, .option)
    }

    func test_backAndUnconnectedDoneDoNotScheduleGuidance() {
        let store = GuidanceStore()
        let setup = DeviceSetupViewModel(link: MockControllerLink(), onClose: {},
            onPairedDone: { store.scheduleAfterPairing() })
        setup.send(.tapDone)
        setup.send(.tapBack)
        XCTAssertFalse(store.isPending)
        setup.send(.linkStateChanged(.connected(latencyMs: 5)))
        setup.send(.tapBack)
        XCTAssertFalse(store.isPending)
    }

    func test_persistenceAndRepeatPairingDoNotRestartACompletedTour() throws {
        let suite = "HomeGuidanceTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = UserDefaultsHomeGuidanceStore(defaults: defaults)
        XCTAssertFalse(first.isPending)
        XCTAssertFalse(first.hasCompleted)
        first.scheduleAfterPairing()
        let reopened = UserDefaultsHomeGuidanceStore(defaults: defaults)
        XCTAssertTrue(reopened.isPending)
        reopened.complete()
        first.scheduleAfterPairing()
        XCTAssertFalse(first.isPending)
        XCTAssertTrue(first.hasCompleted)
        let model = HomeGuidanceViewModel(store: first)
        model.send(.homeAppeared)
        XCTAssertEqual(model.state, .dormant)
    }

    func test_reducerIgnoresEventsOutsideTheTour() {
        XCTAssertEqual(reduce(HomeGuidanceState.dormant, .advance), .dormant)
        XCTAssertEqual(reduce(HomeGuidanceState.finished, .homeAppeared), .finished)
        XCTAssertEqual(reduce(HomeGuidanceState.finished, .advance), .finished)
    }
}

@MainActor
private final class GuidanceStore: HomeGuidanceStore {
    private(set) var isPending = false
    private(set) var hasCompleted = false
    func scheduleAfterPairing() { if !hasCompleted { isPending = true } }
    func complete() { hasCompleted = true; isPending = false }
}
