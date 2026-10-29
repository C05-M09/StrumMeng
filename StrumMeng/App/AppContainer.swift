import Foundation

@MainActor
final class AppContainer {
    private let router: AppRouter
    private let repository: SessionRepository?

    init(router: AppRouter, inMemory: Bool = false) {
        self.router = router
        do {
            let modelContainer = try ModelContainerFactory.make(inMemory: inMemory)
            repository = SwiftDataSessionRepository(modelContainer: modelContainer)
        } catch {
            // A storage failure must show an error rather than a misleading empty history.
            repository = nil
        }
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
}
