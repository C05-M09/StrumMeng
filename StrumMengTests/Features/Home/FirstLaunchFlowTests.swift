import XCTest
@testable import StrumMeng

/// Uses the production factories and router, replacing only persistence, sound and Wi-Fi.
@MainActor
final class FirstLaunchFlowTests: XCTestCase {
    func test_firstLaunchPairsThenShowsOptionAndGuidebookInOrder() throws {
        let invitation = InvitationStore()
        let tour = TourStore()
        let router = AppRouter()
        let container = makeContainer(router: router, invitation: invitation, tour: tour)
        let home = container.makeHomeViewModel()
        let guidance = try XCTUnwrap(home.guidance)
        let intro = container.makePairingIntroductionViewModel()
        defer { intro.setActive(false) }

        guidance.send(.homeAppeared)
        XCTAssertEqual(guidance.state, .dormant)
        intro.setActive(true)
        XCTAssertEqual(intro.state, .waiting)
        intro.send(.delayElapsed)
        XCTAssertEqual(intro.state, .welcoming)
        XCTAssertTrue(router.path.isEmpty, "Welcome must wait for Next")
        intro.send(.continueToSetup)
        XCTAssertEqual(router.path, [.deviceSetup])
        XCTAssertTrue(invitation.hasShownIntroduction)
        XCTAssertFalse(tour.isPending)

        let setup = container.makeDeviceSetupViewModel()
        setup.send(.tapDone)
        XCTAssertEqual(router.path, [.deviceSetup], "Done cannot skip pairing")
        setup.send(.linkStateChanged(.connected(latencyMs: 5)))
        setup.send(.tapDone)
        XCTAssertTrue(router.path.isEmpty)
        XCTAssertTrue(tour.isPending)
        guidance.send(.homeAppeared) // HomeView's production onAppear handoff.
        XCTAssertEqual(guidance.state, .option)
        guidance.send(.advance)
        XCTAssertEqual(guidance.state, .guidebook)
        XCTAssertFalse(tour.hasCompleted)
        guidance.send(.advance)
        XCTAssertEqual(guidance.state, .finished)
        XCTAssertTrue(tour.hasCompleted)
    }

    func test_returningLaunchDoesNotRepeatCompletedOnboarding() throws {
        let invitation = InvitationStore()
        invitation.markIntroductionShown()
        let tour = TourStore()
        tour.complete()
        let router = AppRouter()
        let container = makeContainer(router: router, invitation: invitation, tour: tour)
        let intro = container.makePairingIntroductionViewModel()
        intro.setActive(true)
        XCTAssertEqual(intro.state, .finished)
        let guidance = try XCTUnwrap(container.makeHomeViewModel().guidance)
        guidance.send(.homeAppeared)
        XCTAssertEqual(guidance.state, .dormant)
        XCTAssertTrue(router.path.isEmpty)
    }

    func test_backFromUnfinishedFirstLaunchSetupStartsGuidance() throws {
        let router = AppRouter()
        let tour = TourStore()
        let container = makeContainer(router: router, invitation: InvitationStore(), tour: tour)
        let intro = container.makePairingIntroductionViewModel()
        defer { intro.setActive(false) }
        intro.setActive(true)
        intro.send(.delayElapsed)
        intro.send(.continueToSetup)
        XCTAssertEqual(router.path, [.deviceSetup])
        XCTAssertFalse(tour.isPending)
        container.makeDeviceSetupViewModel().send(.tapBack)
        let guidance = try XCTUnwrap(container.makeHomeViewModel().guidance)
        guidance.send(.homeAppeared)
        XCTAssertTrue(router.path.isEmpty)
        XCTAssertEqual(guidance.state, .option)
        XCTAssertTrue(tour.isPending)
        guidance.send(.advance)
        XCTAssertEqual(guidance.state, .guidebook)
        guidance.send(.advance)
        XCTAssertTrue(tour.hasCompleted)
    }

    func test_backFromSetupDoesNotRepeatCompletedGuidance() throws {
        let router = AppRouter()
        let tour = TourStore()
        tour.complete()
        let container = makeContainer(router: router, invitation: InvitationStore(), tour: tour)
        router.push(.deviceSetup)
        container.makeDeviceSetupViewModel().send(.tapBack)
        let guidance = try XCTUnwrap(container.makeHomeViewModel().guidance)
        guidance.send(.homeAppeared)
        XCTAssertEqual(guidance.state, .dormant)
        XCTAssertFalse(tour.isPending)
    }

    func test_unconnectedDoneKeepsSetupOpenWithoutStartingGuidance() throws {
        let router = AppRouter()
        let tour = TourStore()
        let container = makeContainer(router: router, invitation: InvitationStore(), tour: tour)
        router.push(.deviceSetup)
        container.makeDeviceSetupViewModel().send(.tapDone)
        XCTAssertEqual(router.path, [.deviceSetup])
        XCTAssertFalse(tour.isPending)
    }

    private func makeContainer(router: AppRouter, invitation: InvitationStore,
                               tour: TourStore) -> AppContainer {
        AppContainer(router: router, inMemory: true, menuSounds: MockMenuSoundService(),
                     pairingIntroductionStore: invitation, homeGuidanceStore: tour,
                     controllerLink: MockControllerLink())
    }
}

@MainActor
private final class InvitationStore: PairingIntroductionStore {
    private(set) var hasShownIntroduction = false
    func markIntroductionShown() { hasShownIntroduction = true }
}

@MainActor
private final class TourStore: HomeGuidanceStore {
    private(set) var isPending = false
    private(set) var hasCompleted = false
    func scheduleAfterSetup() { if !hasCompleted { isPending = true } }
    func complete() { hasCompleted = true; isPending = false }
}
