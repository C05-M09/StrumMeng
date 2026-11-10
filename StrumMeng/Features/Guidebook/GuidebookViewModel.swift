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
    private(set) var currentStep: Int? = nil

    @ObservationIgnored private let player: (any ListenPatternPlayer)?
    @ObservationIgnored private let onBackRequested: () -> Void
    @ObservationIgnored private var progressTask: Task<Void, Never>?

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
        progressTask?.cancel()
        do {
            try player.start(pattern: GuidebookTempoConfig.pattern, bpm: bpm)
            isPlayingAudio = true
            currentStep = 0
            observeProgress()
        } catch {
            isPlayingAudio = false
            currentStep = nil
            progressTask = nil
        }
    }

    func stopSound() {
        progressTask?.cancel()
        progressTask = nil
        currentStep = nil
        guard isPlayingAudio else { return }
        player?.stop()
        isPlayingAudio = false
    }

    private func restartSound() {
        guard isPlayingAudio else { return }
        startSound()
    }

    func refreshProgress() {
        guard isPlayingAudio, let player else {
            currentStep = nil
            return
        }
        let pattern = GuidebookTempoConfig.pattern
        guard !pattern.strokes.isEmpty else { return }
        let loopDuration = Double(pattern.beatsPerPattern) * 60.0 / Double(bpm)
        let stepDuration = loopDuration / Double(pattern.strokes.count)
        guard stepDuration > 0 else { return }
        let step = Int(player.elapsed / stepDuration)
        currentStep = step % pattern.strokes.count
    }

    private func observeProgress() {
        progressTask?.cancel()
        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refreshProgress()
                do {
                    try await Task.sleep(for: .milliseconds(16))
                } catch {
                    return
                }
            }
        }
    }

    // MARK: - Dismiss

    func dismiss() {
        stopSound()
        onBackRequested()
    }
}

