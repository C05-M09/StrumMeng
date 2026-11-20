//
//  ShowtimeSummaryViewModelTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import XCTest
@testable import StrumMeng

@MainActor
final class ShowtimeSummaryViewModelTests: XCTestCase {

    private func makeSampleResult(accuracy: Double = 0.88, bpm: Int = 100, songID: String = "twinkle") -> SessionResult {
        SessionResult(
            id: UUID(),
            patternID: "foundation",
            songID: songID,
            bpm: bpm,
            accuracy: accuracy,
            perfectCount: 18,
            tooEarlyCount: 2,
            missCount: 0,
            createdAt: Date(),
            beatEvents: []
        )
    }

    /// Lets queued tasks (the save, then the navigation) run.
    private func settle() async {
        for _ in 0..<50 { await Task.yield() }
    }

    func test_initialState_isShowingWithSessionResult() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository)

        XCTAssertEqual(viewModel.state, .showing(result))
        XCTAssertFalse(viewModel.hasSavedSession)
    }

    func test_starsCalculation_matchesAccuracyBands() {
        let repository = MockSessionRepository()

        let resultZero = makeSampleResult(accuracy: 0.45)
        let vmZero = ShowtimeSummaryViewModel(result: resultZero, repository: repository)
        XCTAssertEqual(vmZero.stars, 0)

        let resultOne = makeSampleResult(accuracy: 0.60)
        let vmOne = ShowtimeSummaryViewModel(result: resultOne, repository: repository)
        XCTAssertEqual(vmOne.stars, 1)

        let resultTwo = makeSampleResult(accuracy: 0.75)
        let vmTwo = ShowtimeSummaryViewModel(result: resultTwo, repository: repository)
        XCTAssertEqual(vmTwo.stars, 2)

        let resultThree = makeSampleResult(accuracy: 0.90)
        let vmThree = ShowtimeSummaryViewModel(result: resultThree, repository: repository)
        XCTAssertEqual(vmThree.stars, 3)
    }

    func test_onAppear_savesSessionToRepositoryExactlyOnce() async {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository)

        await viewModel.onAppear()

        let saved = await repository.savedResults
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.id, result.id)
        XCTAssertEqual(saved.first?.songID, "twinkle")
        XCTAssertTrue(viewModel.hasSavedSession)
    }

    func test_onAppear_calledMultipleTimes_doesNotDoubleSave() async {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository)

        // First appearance
        await viewModel.onAppear()

        // Re-appearance (e.g. user navigated to Replay and returned, or view reloaded)
        await viewModel.onAppear()
        await viewModel.onAppear()

        let saved = await repository.savedResults
        XCTAssertEqual(saved.count, 1, "Session must only be saved once, even if onAppear is triggered multiple times")
    }

    func test_send_tapRetry_transitionsToNavigatingRetry() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository)

        viewModel.send(.tapRetry)

        XCTAssertEqual(viewModel.state, .navigating(.retry))
    }

    func test_retry_navigatesDirectlyToRetryDestination() async {
        var destinations: [ShowtimeSummaryDestination] = []
        let viewModel = ShowtimeSummaryViewModel(
            result: makeSampleResult(),
            repository: MockSessionRepository()
        ) { destinations.append($0) }

        viewModel.send(.tapRetry)
        await settle()

        XCTAssertEqual(destinations, [.retry])
    }

    func test_retry_waitsForTheSaveBeforeNavigating() async {
        let repository = GatedSessionRepository()
        let result = makeSampleResult()
        var destinations: [ShowtimeSummaryDestination] = []
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository) { destinations.append($0) }

        viewModel.send(.tapRetry)
        await settle()
        XCTAssertTrue(destinations.isEmpty, "Must not leave while the session is still being saved")

        await repository.open()
        await settle()
        XCTAssertEqual(destinations, [.retry])
        let saved = await repository.savedResults
        XCTAssertEqual(saved.map(\.id), [result.id])
    }

    func test_backToMain_waitsForTheSaveBeforeNavigating() async {
        let repository = GatedSessionRepository()
        let result = makeSampleResult()
        var destinations: [ShowtimeSummaryDestination] = []
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository) { destinations.append($0) }

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
        let viewModel = ShowtimeSummaryViewModel(result: makeSampleResult(), repository: repository)

        await viewModel.onAppear()
        viewModel.send(.tapBackToMain)
        await settle()

        let saved = await repository.savedResults
        XCTAssertEqual(saved.count, 1)
    }

    func test_tappingRetryTwice_navigatesOnce() async {
        var destinations: [ShowtimeSummaryDestination] = []
        let viewModel = ShowtimeSummaryViewModel(
            result: makeSampleResult(),
            repository: MockSessionRepository()
        ) { destinations.append($0) }

        viewModel.send(.tapRetry)
        viewModel.send(.tapRetry)
        await settle()

        XCTAssertEqual(destinations, [.retry])
    }

    func test_tappingBackToMainTwice_navigatesOnce() async {
        var destinations: [ShowtimeSummaryDestination] = []
        let viewModel = ShowtimeSummaryViewModel(
            result: makeSampleResult(),
            repository: MockSessionRepository()
        ) { destinations.append($0) }

        viewModel.send(.tapBackToMain)
        viewModel.send(.tapBackToMain)
        await settle()

        XCTAssertEqual(destinations, [.backToMain])
    }

    func test_send_tapReplay_navigatesToReplay() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository)

        viewModel.send(.tapReplay)

        XCTAssertEqual(viewModel.state, .navigating(.replay(result)))
    }

    func test_returnFromReplay_allowsReplayToBeEnteredAgain() {
        let repository = MockSessionRepository()
        let result = makeSampleResult()
        let viewModel = ShowtimeSummaryViewModel(result: result, repository: repository)

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

    func test_replay_isShownBySummaryItself_soNothingIsNavigated() async {
        var destinations: [ShowtimeSummaryDestination] = []
        let viewModel = ShowtimeSummaryViewModel(
            result: makeSampleResult(),
            repository: MockSessionRepository()
        ) { destinations.append($0) }

        viewModel.send(.tapReplay)
        await settle()

        XCTAssertTrue(destinations.isEmpty)
    }
}

