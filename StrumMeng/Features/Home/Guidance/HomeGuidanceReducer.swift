func reduce(_ state: HomeGuidanceState, _ event: HomeGuidanceEvent) -> HomeGuidanceState {
    switch (state, event) {
    case (.dormant, .homeAppeared): return .option
    case (.option, .advance): return .guidebook
    case (.guidebook, .advance): return .finished
    default: return state
    }
}
