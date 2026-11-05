//
//  GuidebookViewModel.swift
//  StrumMeng
//
//  Created by sharon on 30/10/26.
//

import Foundation
import Observation

/// Manages the Guidebook state, page navigation, and the interactive tempo controls on Page 2.
@MainActor
@Observable
final class GuidebookViewModel {
    let pages: [GuidebookPage]

    private(set) var currentPageIndex: Int = 0
    private(set) var bpm: Int = GuidebookTempoConfig.defaultBPM
    private(set) var isPlayingAudio: Bool = false

    @ObservationIgnored private let player: (any ListenPatternPlayer)?
    @ObservationIgnored private let onBackRequested: () -> Void

    init(
        pages: [GuidebookPage] = GuidebookCatalog.pages,
        player: (any ListenPatternPlayer)? = nil,
        onBackRequested: @escaping () -> Void
    ) {
        self.pages = pages
        self.player = player
        self.onBackRequested = onBackRequested
    }

    var currentPage: GuidebookPage {
        guard currentPageIndex >= 0 && currentPageIndex < pages.count else {
            return pages.first ?? GuidebookPage(id: "fallback", title: "", backgroundAsset: "")
        }
        return pages[currentPageIndex]
    }

    var canDecreaseBPM: Bool {
        bpm - GuidebookTempoConfig.stepBPM >= GuidebookTempoConfig.minBPM
    }

    var canIncreaseBPM: Bool {
        bpm + GuidebookTempoConfig.stepBPM <= GuidebookTempoConfig.maxBPM
    }

    var hasNextPage: Bool {
        pages.count > 1
    }

    var hasPreviousPage: Bool {
        pages.count > 1
    }

    // MARK: - Page Navigation

    func setPage(index: Int) {
        guard index >= 0 && index < pages.count else { return }
        if index != currentPageIndex {
            stopSound()
        }
        currentPageIndex = index
    }

    func nextPage() {
        guard !pages.isEmpty else { return }
        let nextIndex = (currentPageIndex + 1) % pages.count
        setPage(index: nextIndex)
    }

    func previousPage() {
        guard !pages.isEmpty else { return }
        let prevIndex = (currentPageIndex - 1 + pages.count) % pages.count
        setPage(index: prevIndex)
    }

    // MARK: - Tempo Controls (Page 2)

    func increaseBPM() {
        guard canIncreaseBPM else { return }
        bpm += GuidebookTempoConfig.stepBPM
        if isPlayingAudio {
            restartSound()
        }
    }

    func decreaseBPM() {
        guard canDecreaseBPM else { return }
        bpm -= GuidebookTempoConfig.stepBPM
        if isPlayingAudio {
            restartSound()
        }
    }

    // MARK: - Audio Playback

    func toggleSoundPreview() {
        if isPlayingAudio {
            stopSound()
        } else {
            startSound()
        }
    }

    func startSound() {
        guard let player else { return }
        do {
            try player.start(pattern: GuidebookTempoConfig.pattern, bpm: bpm)
            isPlayingAudio = true
        } catch {
            isPlayingAudio = false
        }
    }

    func stopSound() {
        guard isPlayingAudio else { return }
        player?.stop()
        isPlayingAudio = false
    }

    private func restartSound() {
        guard isPlayingAudio else { return }
        startSound()
    }

    // MARK: - Dismiss

    func dismiss() {
        stopSound()
        onBackRequested()
    }
}

