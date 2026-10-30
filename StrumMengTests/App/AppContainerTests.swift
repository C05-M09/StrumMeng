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

    func test_homeViewModel_tapShowtime_doesNotPushRoute() {
        let home = sut.makeHomeViewModel()

        home.send(.tapShowtime)

        XCTAssertEqual(router.path.count, 0)
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
}
