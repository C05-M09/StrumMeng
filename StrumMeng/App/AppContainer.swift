import Foundation

@MainActor
final class AppContainer {

    private let router: AppRouter
    private let settings: any SettingsStore

    init(
        router: AppRouter,
        settings: (any SettingsStore)? = nil
    ) {
        self.router = router
        self.settings = settings ?? UserDefaultsSettingsStore()
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            onPracticeRequested: { [weak router] in
                router?.push(.practiceList)
            }
        )
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

    /// Option is an overlay on Home, so whoever shows it decides what "back" means
    /// (close the overlay), instead of popping the router.
    func makeOptionViewModel(onBackRequested: @escaping () -> Void) -> OptionViewModel {
        OptionViewModel(
            settings: settings,
            onBackRequested: onBackRequested
        )
    }
}
