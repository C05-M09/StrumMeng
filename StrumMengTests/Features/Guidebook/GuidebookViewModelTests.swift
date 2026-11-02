//
//  GuidebookViewModelTests.swift
//  StrumMengTests
//
//  Created by sharon on 30/10/26.
//

import XCTest
@testable import StrumMeng

@MainActor
final class GuidebookViewModelTests: XCTestCase {

    @MainActor
    private final class MockListenPlayer: ListenPatternPlayer {
        var elapsed: TimeInterval = 0
        var startCount = 0
        var stopCount = 0
        var lastBPM: Int?
        var lastPattern: StrumPattern?
        var shouldFail = false

        init() {}

        func start(pattern: StrumPattern, bpm: Int) throws {
            if shouldFail {
                throw NSError(domain: "MockListenPlayer", code: 1, userInfo: nil)
            }
            startCount += 1
            lastBPM = bpm
            lastPattern = pattern
        }

        func pause() {}
        func resume() {}

        func stop() {
            stopCount += 1
        }
    }

    private func makeSUT(
        player: MockListenPlayer? = nil,
        onBack: @escaping () -> Void = {}
    ) -> (sut: GuidebookViewModel, player: MockListenPlayer) {
        let activePlayer = player ?? MockListenPlayer()
        let sut = GuidebookViewModel(
            player: activePlayer,
            onBackRequested: onBack
        )
        return (sut, activePlayer)
    }

    // MARK: - Initial State

    func test_init_loadsCatalogPagesAndDefaultState() {
        let (sut, _) = makeSUT()

        XCTAssertEqual(sut.pages.count, 3)
        XCTAssertEqual(sut.currentPageIndex, 0)
        XCTAssertEqual(sut.currentPage.id, "counting-beats")
        XCTAssertEqual(sut.bpm, 60)
        XCTAssertFalse(sut.canDecreaseBPM, "BPM 60 adalah nilai minimum")
        XCTAssertTrue(sut.canIncreaseBPM)
        XCTAssertFalse(sut.isPlayingAudio)
        XCTAssertTrue(sut.hasNextPage)
        XCTAssertTrue(sut.hasPreviousPage)
    }

    // MARK: - Page Navigation

    func test_nextPage_and_previousPage_navigatesAndLoopsCorrectly() {
        let (sut, _) = makeSUT()

        // Page 0 -> Page 1
        sut.nextPage()
        XCTAssertEqual(sut.currentPageIndex, 1)
        XCTAssertEqual(sut.currentPage.id, "practice-tempo")
        XCTAssertTrue(sut.currentPage.isInteractiveTempo)

        // Page 1 -> Page 2
        sut.nextPage()
        XCTAssertEqual(sut.currentPageIndex, 2)
        XCTAssertEqual(sut.currentPage.id, "how-to-strum")

        // Next at last page loops back to page 0
        sut.nextPage()
        XCTAssertEqual(sut.currentPageIndex, 0)
        XCTAssertEqual(sut.currentPage.id, "counting-beats")

        // Previous at first page loops back to page 2
        sut.previousPage()
        XCTAssertEqual(sut.currentPageIndex, 2)
        XCTAssertEqual(sut.currentPage.id, "how-to-strum")

        // Page 2 -> Page 1
        sut.previousPage()
        XCTAssertEqual(sut.currentPageIndex, 1)
    }

    func test_setPage_withValidAndInvalidIndices() {
        let (sut, _) = makeSUT()

        sut.setPage(index: 2)
        XCTAssertEqual(sut.currentPageIndex, 2)

        // Invalid negative index
        sut.setPage(index: -1)
        XCTAssertEqual(sut.currentPageIndex, 2, "Indeks negatif harus diabaikan")

        // Invalid out of bounds index
        sut.setPage(index: 99)
        XCTAssertEqual(sut.currentPageIndex, 2, "Indeks melebihi batas harus diabaikan")
    }

    func test_setPage_stopsAudioWhenSwitchingPage() {
        let (sut, player) = makeSUT()
        sut.setPage(index: 1) // Halaman tempo
        sut.startSound()
        XCTAssertTrue(sut.isPlayingAudio)

        // Pindah halaman
        sut.setPage(index: 0)
        XCTAssertFalse(sut.isPlayingAudio)
        XCTAssertEqual(player.stopCount, 1)
    }

    // MARK: - BPM Adjustment

    func test_bpm_increaseAndDecreaseBy5WithinBounds() {
        let (sut, _) = makeSUT()

        XCTAssertEqual(sut.bpm, 60)

        // Cannot decrease below 60
        sut.decreaseBPM()
        XCTAssertEqual(sut.bpm, 60)
        XCTAssertFalse(sut.canDecreaseBPM)

        // Increase by 5
        sut.increaseBPM()
        XCTAssertEqual(sut.bpm, 65)
        XCTAssertTrue(sut.canDecreaseBPM)

        // Increase up to 120
        for _ in 0..<11 {
            sut.increaseBPM()
        }
        XCTAssertEqual(sut.bpm, 120)
        XCTAssertFalse(sut.canIncreaseBPM, "BPM 120 adalah batas maksimum")

        // Cannot increase beyond 120
        sut.increaseBPM()
        XCTAssertEqual(sut.bpm, 120)

        // Decrease back
        sut.decreaseBPM()
        XCTAssertEqual(sut.bpm, 115)
        XCTAssertTrue(sut.canIncreaseBPM)
    }

    func test_bpm_changeWhilePlaying_restartsPlaybackWithNewBPM() {
        let (sut, player) = makeSUT()
        sut.startSound()
        XCTAssertEqual(player.startCount, 1)
        XCTAssertEqual(player.lastBPM, 60)

        sut.increaseBPM()
        XCTAssertEqual(sut.bpm, 65)
        XCTAssertEqual(player.startCount, 2)
        XCTAssertEqual(player.lastBPM, 65)

        sut.decreaseBPM()
        XCTAssertEqual(sut.bpm, 60)
        XCTAssertEqual(player.startCount, 3)
        XCTAssertEqual(player.lastBPM, 60)
    }

    // MARK: - Audio Playback

    func test_toggleSoundPreview_startsAndStopsAudio() {
        let (sut, player) = makeSUT()

        // Toggle on
        sut.toggleSoundPreview()
        XCTAssertTrue(sut.isPlayingAudio)
        XCTAssertEqual(player.startCount, 1)
        XCTAssertEqual(player.lastPattern?.id, "guidebook-tempo")
        XCTAssertEqual(player.lastBPM, 60)

        // Toggle off
        sut.toggleSoundPreview()
        XCTAssertFalse(sut.isPlayingAudio)
        XCTAssertEqual(player.stopCount, 1)
    }

    func test_audioPlayback_failureSetsIsPlayingToFalse() {
        let (sut, player) = makeSUT()
        player.shouldFail = true

        sut.startSound()
        XCTAssertFalse(sut.isPlayingAudio)
    }

    // MARK: - Dismiss

    func test_dismiss_stopsAudioAndCallsCallback() {
        var didBack = false
        let (sut, player) = makeSUT(onBack: { didBack = true })

        sut.startSound()
        XCTAssertTrue(sut.isPlayingAudio)

        sut.dismiss()
        XCTAssertFalse(sut.isPlayingAudio)
        XCTAssertEqual(player.stopCount, 1)
        XCTAssertTrue(didBack)
    }
}

