import Foundation

@MainActor
final class AppContainer {
    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    func makeListenViewModel(pattern: StrumPattern, bpm: Int) -> ListenViewModel {
        ListenViewModel(pattern: pattern, bpm: bpm, player: GuitarListenPlayer(),
                        onReady: { [weak router] in router?.push(.play(patternID: pattern.id, bpm: bpm)) },
                        onBack: { [weak router] in router?.popToRoot() })
    }

    func makePlayViewModel(pattern: StrumPattern, bpm: Int) -> PlayViewModel {
        let input = TouchStrumInputService()
        return PlayViewModel(pattern: pattern, bpm: bpm, clock: AudioBeatClock(),
                             input: input, touchInput: input, now: HostClock.now,
                             waitUntil: { time in
            let delay = time - HostClock.now()
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
        }, onExit: { [weak router] in router?.popToRoot() })
    }

    func makePatternListViewModel() -> PatternListViewModel {
        PatternListViewModel(
            onListenRequested: { [weak router] patternID, bpm in
                router?.push(.listen(patternID: patternID, bpm: bpm))
            },
            onBackRequested: { [weak router] in
                router?.pop()
            }
        )
    }
}
