import SwiftUI

struct ContentView: View {
    @State private var router: AppRouter
    @State private var patternListViewModel: PatternListViewModel

    init() {
        let router = AppRouter()
        let container = AppContainer(router: router)
        _router = State(initialValue: router)
        _patternListViewModel = State(initialValue: container.makePatternListViewModel())
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            PatternListView(viewModel: patternListViewModel)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case let .listen(patternID, bpm):
                        if let pattern = PatternCatalog.all.first(where: { $0.id == patternID }) {
                            ListenPlaceholderView(
                                pattern: pattern,
                                bpm: bpm,
                                onBack: { router.pop() }
                            )
                        }
                    }
                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
