import Foundation

@MainActor
final class AppContainer {

    private let router: AppRouter
   private let repository: SessionRepository?
  private let settings: any SettingsStore

init(
    router: AppRouter,
    inMemory: Bool = false,
    settings: (any SettingsStore)? = nil
) {
    self.router = router
    self.settings = settings ?? UserDefaultsSettingsStore()

    do {
        let modelContainer = try ModelContainerFactory.make(
            inMemory: inMemory
        )
        repository = SwiftDataSessionRepository(
            modelContainer: modelContainer
        )
    } catch {
        // Show a records error when storage cannot be initialized.
        repository = nil
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            onPracticeRequested: { [weak router] in
                router?.push(.practiceList)
            }
        )
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
        let records = repository.map { repository in
            Dictionary(uniqueKeysWithValues: PatternCatalog.all.map { pattern in
                (pattern.id, RecordsViewModel(patternID: pattern.id, repository: repository))
            })
        } ?? [:]
        return PatternListViewModel(
            recordsViewModels: records,
            recordsFallbackState: repository == nil ? .failed : .empty,
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
