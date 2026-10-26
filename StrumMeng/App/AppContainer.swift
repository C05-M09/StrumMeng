import Foundation

@MainActor
final class AppContainer {
    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
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
