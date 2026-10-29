#if DEBUG
import SwiftUI

@MainActor
enum ListenPreviewFactory {
    static func make(events: [ListenEvent], elapsed: TimeInterval = 0) -> ListenView {
        AppFontRegistrar.registerFonts()
        let model = ListenViewModel(pattern: PatternCatalog.all[1], bpm: 80,
                                    player: ListenPreviewPlayer(elapsed: elapsed), onReady: {}, onBack: {})
        for event in events { model.send(event) }
        model.refreshProgress()
        return ListenView(viewModel: model)
    }
}

@MainActor
private final class ListenPreviewPlayer: ListenPatternPlayer {
    let elapsed: TimeInterval
    init(elapsed: TimeInterval) { self.elapsed = elapsed }
    func start(pattern: StrumPattern, bpm: Int) throws {}
    func pause() {}
    func resume() {}
    func stop() {}
}

#endif
