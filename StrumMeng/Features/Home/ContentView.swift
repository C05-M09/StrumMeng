import SwiftUI

struct ContentView: View {
    @State private var router: AppRouter
    @State private var homeViewModel: HomeViewModel
    @State private var patternListViewModel: PatternListViewModel
    @State private var optionViewModel: OptionViewModel

    init(inMemory: Bool = false) {
        let router = AppRouter()
      let container = AppContainer(
    router: router,
    inMemory: inMemory
)

        _router = State(initialValue: router)
        _homeViewModel = State(initialValue: homeViewModel)
        _patternListViewModel = State(initialValue: container.makePatternListViewModel())
        // Option is an overlay on Home, so "back" closes the overlay instead of popping the router.
        _optionViewModel = State(initialValue: container.makeOptionViewModel { [weak homeViewModel] in
            homeViewModel?.send(.dismissOverlay)
        })
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            HomeView(viewModel: homeViewModel, optionViewModel: optionViewModel)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .practiceList:
                        PatternListView(viewModel: patternListViewModel)
                        
                    case let .listen(patternID, bpm):
                        if let pattern = PatternCatalog.all.first(where: { $0.id == patternID }) {
                            ListenPlaceholderView(pattern: pattern, bpm: bpm, onBack: { router.pop() })
                            ListenView(viewModel: AppContainer(router: router)
                                .makeListenViewModel(pattern: pattern, bpm: bpm))
                        }
                    case let .play(patternID, bpm):
                        if let pattern = PatternCatalog.all.first(where: { $0.id == patternID }) {
                            PracticePlaySessionView(viewModel: AppContainer(router: router)
                                .makePlayViewModel(pattern: pattern, bpm: bpm), startImmediately: true)
                                .navigationBarBackButtonHidden()
                        }
                    }
                    
                    //                    case .guidebook:
                    //                        GuidebookPlaceholderView(onBack: { router.pop() })
                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView(inMemory: true)
}
