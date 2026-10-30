//
//  SummaryViewModelTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import XCTest
@testable import StrumMeng

@MainActor
final class SummaryViewModelTests: XCTestCase {

    private func makeSampleResult(accuracy: Double = 0.88, bpm: Int = 80) -> SessionResult {
        SessionResult(
            id: UUID(),
            patternID: "foundation",
            songID: nil,
            bpm: bpm,
            accuracy: accuracy,
            perfectCount: 18,
            tooEarlyCount: 2,
            missCount: 0,
            createdAt: Date(),
            beatEvents: []
        )
    }

    func test_initialState_isShowingWithSessionResult() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = SummaryViewModel(result: result, repository: repository)

        XCTAssertEqual(viewModel.state, .showing(result))
        XCTAssertFalse(viewModel.hasSavedSession)
    }

    func test_onAppear_savesSessionToRepositoryExactlyOnce() async {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = SummaryViewModel(result: result, repository: repository)

        await viewModel.onAppear()

        let saved = await repository.savedResults
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.id, result.id)
        XCTAssertTrue(viewModel.hasSavedSession)
    }

    func test_onAppear_calledMultipleTimes_doesNotDoubleSave() async {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = SummaryViewModel(result: result, repository: repository)

        // First appearance
        await viewModel.onAppear()

        // Re-appearance (e.g. user navigated to Replay and returned, or view reloaded)
        await viewModel.onAppear()
        await viewModel.onAppear()

        let saved = await repository.savedResults
        XCTAssertEqual(saved.count, 1, "Session must only be saved once, even if onAppear is triggered multiple times")
    }

    func test_send_tapRetryAndAcceptRecommendation_updatesStateToNavigatingRetry() {
        let repository = MockSessionRepository()
        let result = makeSampleResult(accuracy: 0.90, bpm: 80)
        let viewModel = SummaryViewModel(result: result, repository: repository)

        viewModel.send(.tapRetry)

        guard case .showingRecommendation(let recommendation) = viewModel.state else {
            XCTFail("Expected showingRecommendation state")
            return
        }
        XCTAssertEqual(recommendation.targetBPM, 90)

        viewModel.send(.acceptRecommendation)
        XCTAssertEqual(viewModel.state, .navigating(.retry(bpm: 90)))
    }

    func test_send_tapRetryAndRejectRecommendation_updatesStateToNavigatingRetryWithCurrentBPM() {
        let repository = MockSessionRepository()
        let result = makeSampleResult(accuracy: 0.90, bpm: 80)
        let viewModel = SummaryViewModel(result: result, repository: repository)

        viewModel.send(.tapRetry)
        viewModel.send(.rejectRecommendation)

        XCTAssertEqual(viewModel.state, .navigating(.retry(bpm: 80)))
    }

    func test_send_tapReplay_navigatesToReplay() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = SummaryViewModel(result: result, repository: repository)

        viewModel.send(.tapReplay)

        XCTAssertEqual(viewModel.state, .navigating(.replay(result)))
    }

    func test_returnFromReplay_allowsReplayToBeEnteredAgain() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = SummaryViewModel(result: result, repository: repository)

        // 1. Enter Replay
        viewModel.send(.tapReplay)
        XCTAssertEqual(viewModel.state, .navigating(.replay(result)))

        // 2. Return from Replay
        viewModel.send(.returnFromReplay)
        XCTAssertEqual(viewModel.state, .showing(result))

        // 3. Can enter Replay again
        viewModel.send(.tapReplay)
        XCTAssertEqual(viewModel.state, .navigating(.replay(result)))
    }

    func test_send_tapBackToMain_navigatesToBackToMain() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = SummaryViewModel(result: result, repository: repository)

        viewModel.send(.tapBackToMain)

        XCTAssertEqual(viewModel.state, .navigating(.backToMain))
    }
    // MARK: - Navigation

    /// Lets queued tasks (the save, then the navigation) run.
    private func settle() async {
        for _ in 0..<50 { await Task.yield() }
    }

    func test_retry_navigatesWithTheChosenBPM() async {
        var destinations: [SummaryDestination] = []
        let viewModel = SummaryViewModel(result: makeSampleResult(accuracy: 0.90, bpm: 80),
                                         repository: MockSessionRepository()) { destinations.append($0) }

        viewModel.send(.tapRetry)
        viewModel.send(.acceptRecommendation)
        await settle()

        XCTAssertEqual(destinations, [.retry(bpm: 90)])
    }

    func test_backToMain_waitsForTheSaveBeforeNavigating() async {
        let repository = GatedSessionRepository()
        let result = makeSampleResult()
        var destinations: [SummaryDestination] = []
        let viewModel = SummaryViewModel(result: result, repository: repository) { destinations.append($0) }

        viewModel.send(.tapBackToMain)
        await settle()
        XCTAssertTrue(destinations.isEmpty, "Must not leave while the session is still being saved")

        await repository.open()
        await settle()
        XCTAssertEqual(destinations, [.backToMain])
        let saved = await repository.savedResults
        XCTAssertEqual(saved.map(\.id), [result.id])
    }

    func test_leavingAfterOnAppear_doesNotSaveAgain() async {
        let repository = MockSessionRepository()
        let viewModel = SummaryViewModel(result: makeSampleResult(), repository: repository)

        await viewModel.onAppear()
        viewModel.send(.tapBackToMain)
        await settle()

        let saved = await repository.savedResults
        XCTAssertEqual(saved.count, 1)
    }

    func test_tappingBackToMainTwice_navigatesOnce() async {
        var destinations: [SummaryDestination] = []
        let viewModel = SummaryViewModel(result: makeSampleResult(),
                                         repository: MockSessionRepository()) { destinations.append($0) }

        viewModel.send(.tapBackToMain)
        viewModel.send(.tapBackToMain)
        await settle()

        XCTAssertEqual(destinations, [.backToMain])
    }

    func test_replay_isShownBySummaryItself_soNothingIsNavigated() async {
        var destinations: [SummaryDestination] = []
        let viewModel = SummaryViewModel(result: makeSampleResult(),
                                         repository: MockSessionRepository()) { destinations.append($0) }

        viewModel.send(.tapReplay)
        await settle()

        XCTAssertTrue(destinations.isEmpty)
    }
}
