func reduce(_ state: PairingIntroductionState,
            _ event: PairingIntroductionEvent) -> PairingIntroductionState {
    switch (state, event) {
    case (.idle, .begin): return .waiting
    case (.waiting, .delayElapsed): return .welcoming
    case (.welcoming, .continueToSetup), (.idle, .skip): return .finished
    case (.waiting, .cancel), (.welcoming, .cancel): return .idle
    default: return state
    }
}
