import SwiftUI

struct ContentView: View {
    @State private var router: AppRouter
    @State private var container: AppContainer
    @State private var homeViewModel: HomeViewModel
    @State private var patternListViewModel: PatternListViewModel
    @State private var optionViewModel: OptionViewModel

    init(inMemory:Bool = false) {
        let router = AppRouter()
        let container = AppContainer(router: router, inMemory: inMemory)
        let homeViewModel = container.makeHomeViewModel()

        _router = State(initialValue: router)
        _container = State(initialValue: container)
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

                    case let .listen(patternID, bpm, _):
                        if let pattern = PatternCatalog.all.first(where: { $0.id == patternID }) {
                            // A screen per route value: at the same stack position, SwiftUI would
                            // otherwise keep the previous Listen and its finished view model.
                            ListenRoute(pattern: pattern, bpm: bpm, container: container)
                                .id(route)
                        }

                    case let .play(patternID, bpm):
                        if let pattern = PatternCatalog.all.first(where: { $0.id == patternID }) {
                            PlayRoute(pattern: pattern, bpm: bpm, container: container)
                                .id(route)
                                .navigationBarBackButtonHidden()
                        }

                    case let .summary(sessionID):
                        SummaryRoute(sessionID: sessionID, container: container)
                            .id(route)
                            .navigationBarBackButtonHidden()
                    }
                }
        }
        .ignoresSafeArea()
    }
}

/// Keeps one `ListenViewModel` for as long as the screen is on the stack.
/// Without this, every redraw of `ContentView` would build a new view model and restart the screen.
private struct ListenRoute: View {
    @State private var viewModel: ListenViewModel

    init(pattern: StrumPattern, bpm: Int, container: AppContainer) {
        _viewModel = State(initialValue: container.makeListenViewModel(pattern: pattern, bpm: bpm))
    }

    var body: some View {
        ListenView(viewModel: viewModel)
    }
}

/// Same idea for the Play screen, so a redraw cannot reset a running session.
private struct PlayRoute: View {
    @State private var viewModel: PlayViewModel

    init(pattern: StrumPattern, bpm: Int, container: AppContainer) {
        _viewModel = State(initialValue: container.makePlayViewModel(pattern: pattern, bpm: bpm))
    }

    var body: some View {
        PracticePlaySessionView(viewModel: viewModel, startImmediately: true)
    }
}

/// Same idea for Summary, so a redraw cannot save the session twice or reset the overlays.
private struct SummaryRoute: View {
    @State private var viewModel: SummaryViewModel?

    init(sessionID: UUID, container: AppContainer) {
        _viewModel = State(initialValue: container.makeSummaryViewModel(sessionID: sessionID))
    }

    var body: some View {
        if let viewModel {
            SummaryView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView(inMemory: true)
}
