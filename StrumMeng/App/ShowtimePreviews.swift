import SwiftUI

#if DEBUG
#Preview("Showtime • Interactive flow, no iPhone", traits: .landscapeLeft) {
    ShowtimeSessionView(viewModel: AppContainer.makeShowtimePreviewViewModel())
}
#Preview("Showtime • Introduction", traits: .landscapeLeft) {
    Image("Showtime_Assets/Showtime_BG").resizable().overlay { ShowtimeIntroView(onNext: {}) }
        .frame(width: ShowtimeLayout.size.width, height: ShowtimeLayout.size.height)
}
#Preview("Showtime • Finished", traits: .landscapeLeft) {
    ShowtimeFinishedView(title: "Twinkle Twinkle Little Star",
        result: SessionResult(id: UUID(), patternID: "foundation", songID: "dummy-twinkle", bpm: 80,
            accuracy: 0.8, perfectCount: 56, tooEarlyCount: 16, missCount: 8,
            createdAt: Date(), beatEvents: []), onRestart: {}, onBack: {})
        .frame(width: ShowtimeLayout.size.width, height: ShowtimeLayout.size.height)
}
#Preview("Showtime • Song cards", traits: .landscapeLeft) {
    SongListView(viewModel: SongListViewModel(catalog: DummySongCatalog(), onSelect: { _ in }, onBack: {}))
}
#Preview("Showtime • Listen, Ready locked", traits: .landscapeLeft) {
    ShowtimeListenPreview(patternIndex: 0, activeStep: 3, canReady: false)
        .frame(width: ShowtimeLayout.size.width, height: ShowtimeLayout.size.height)
}
#Preview("Showtime • Listen finished", traits: .landscapeLeft) {
    ShowtimeListenPreview(patternIndex: 1, activeStep: 0, canReady: true)
        .frame(width: ShowtimeLayout.size.width, height: ShowtimeLayout.size.height)
}
#Preview("Showtime • Moving chords", traits: .landscapeLeft) {
    ShowtimePlayPreview(phase: .playing)
}
#Preview("Showtime • Ready?", traits: .landscapeLeft) {
    ShowtimePlayPreview(phase: .ready)
}
#Preview("Showtime • Count-in", traits: .landscapeLeft) {
    ShowtimePlayPreview(phase: .countIn(2))
}
#Preview("Showtime • Pause", traits: .landscapeLeft) {
    ShowtimePlayPreview(phase: .paused)
}
#Preview("Showtime • Disconnected", traits: .landscapeLeft) {
    ShowtimePlayPreview(phase: .disconnected(isReconnected: false))
}

private struct ShowtimeListenPreview: View {
    let patternIndex: Int
    let activeStep: Int
    let canReady: Bool
    var body: some View {
        let timeline = SongTimeline(song: DummySongCatalog().songs[1])
        ShowtimeListenView(title: timeline.song.title, bpm: timeline.song.bpm,
            pattern: timeline.previewPatterns[patternIndex], activeStep: activeStep, canReady: canReady,
            patternIndex: patternIndex, patternCount: timeline.previewPatterns.count,
            onSelectPattern: { _ in }, onReady: {}, onPause: {})
    }
}

private struct ShowtimePlayPreview: View {
    let phase: PlayScreenPhase
    var body: some View {
        let timeline = SongTimeline(song: DummySongCatalog().songs[0])
        let nodes = PlayTimeline.makeNodes(pattern: timeline.strokes.map { stroke in
            switch stroke {
            case .down: BeatNodeView.Arrow.down
            case .up: BeatNodeView.Arrow.up
            case .rest: nil
            }
        }, slotInterval: timeline.slotInterval, duration: timeline.duration)
        PracticePlayView(model: PlayScreenModel(title: timeline.song.title, bpm: timeline.song.bpm,
            duration: timeline.duration, slotInterval: timeline.slotInterval, songTime: 5,
            phase: phase, nodes: nodes, lastJudgement: nil, chordLabels: timeline.chordLabels,
            titleLines: TitleLineWrapping.lines(for: timeline.song.title)),
            backgroundAssetName: "Showtime_Assets/Showtime_BG", titleFontScale: 0.8,
            titleLineSpacing: ShowtimeLayout.titleLineSpacing, bpmColor: AppColors.white)
    }
}
#endif
