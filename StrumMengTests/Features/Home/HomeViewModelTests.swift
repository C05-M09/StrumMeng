//
//  HomeViewModelTests.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//

import XCTest
@testable import StrumMeng

@MainActor
final class HomeViewModelTests: XCTestCase {

    private final class CallbackRecorder {
        var practiceCount = 0
    }

    private func makeSUT() -> (sut: HomeViewModel, recorder: CallbackRecorder) {
        let recorder = CallbackRecorder()
        let sut = HomeViewModel(onPracticeRequested: { recorder.practiceCount += 1 })
        return (sut, recorder)
    }

    // MARK: - Initial state

    func test_init_noOverlayIsShown() {
        let (sut, recorder) = makeSUT()

        XCTAssertNil(sut.presentedOverlay)
        XCTAssertEqual(recorder.practiceCount, 0, "init tidak boleh memicu callback")
    }

    // MARK: - Option overlay

    func test_tapOption_showsOptionOverlay() {
        let (sut, _) = makeSUT()

        sut.send(.tapOption)

        XCTAssertEqual(sut.presentedOverlay, .option)
    }

    func test_tapOption_doesNotNavigate() {
        let (sut, recorder) = makeSUT()

        sut.send(.tapOption)

        XCTAssertEqual(recorder.practiceCount, 0, "Option adalah overlay, bukan route")
    }

    // MARK: - Guidebook overlay

    func test_tapGuidebook_showsGuidebookOverlay() {
        let (sut, _) = makeSUT()

        sut.send(.tapGuidebook)

        XCTAssertEqual(sut.presentedOverlay, .guidebook)
    }

    func test_tapGuidebook_doesNotNavigate() {
        let (sut, recorder) = makeSUT()

        sut.send(.tapGuidebook)

        XCTAssertEqual(recorder.practiceCount, 0, "Guidebook adalah overlay, bukan route")
    }

    // MARK: - Dismiss

    func test_dismissOverlay_hidesOption() {
        let (sut, _) = makeSUT()
        sut.send(.tapOption)

        sut.send(.dismissOverlay)

        XCTAssertNil(sut.presentedOverlay)
    }

    func test_dismissOverlay_hidesGuidebook() {
        let (sut, _) = makeSUT()
        sut.send(.tapGuidebook)

        sut.send(.dismissOverlay)

        XCTAssertNil(sut.presentedOverlay)
    }

    func test_dismissOverlay_whenNothingShown_staysHidden() {
        let (sut, _) = makeSUT()

        sut.send(.dismissOverlay)

        XCTAssertNil(sut.presentedOverlay)
    }

    func test_overlay_canBeReopenedAfterDismiss() {
        let (sut, _) = makeSUT()

        sut.send(.tapOption)
        sut.send(.dismissOverlay)
        sut.send(.tapGuidebook)

        XCTAssertEqual(sut.presentedOverlay, .guidebook)
    }

    func test_tapOption_thenTapGuidebook_replacesOverlay() {
        let (sut, _) = makeSUT()

        sut.send(.tapOption)
        sut.send(.tapGuidebook)

        XCTAssertEqual(sut.presentedOverlay, .guidebook, "Hanya satu overlay dalam satu waktu")
    }

    // MARK: - Practice

    func test_tapPractice_callsPracticeCallbackOnce() {
        let (sut, recorder) = makeSUT()

        sut.send(.tapPractice)

        XCTAssertEqual(recorder.practiceCount, 1)
    }

    func test_tapPractice_doesNotShowOverlay() {
        let (sut, _) = makeSUT()

        sut.send(.tapPractice)

        XCTAssertNil(sut.presentedOverlay)
    }

    // MARK: - Showtime

    func test_tapShowtime_doesNothing() {
        let (sut, recorder) = makeSUT()

        sut.send(.tapShowtime)

        XCTAssertEqual(recorder.practiceCount, 0, "Showtime tidak boleh navigasi")
        XCTAssertNil(sut.presentedOverlay, "Showtime tidak boleh membuka overlay")
    }

    func test_tapShowtime_whileOverlayShown_keepsOverlay() {
        let (sut, _) = makeSUT()
        sut.send(.tapOption)

        sut.send(.tapShowtime)

        XCTAssertEqual(sut.presentedOverlay, .option)
    }
}
