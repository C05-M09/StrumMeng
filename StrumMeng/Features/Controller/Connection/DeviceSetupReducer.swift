import Foundation

func reduce(_ state: DeviceSetupState, _ event: DeviceSetupEvent) -> DeviceSetupState {
    switch event {
    case .simulateNextState:
        switch state {
        case .searching: return .connected
        case .connected: return .reconnecting
        case .reconnecting: return .searching
        }

    case .tapDone, .tapBack:
        return state
    }
}
