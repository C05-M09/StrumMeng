import Foundation

func reduce(_ state: DeviceSetupState, _ event: DeviceSetupEvent) -> DeviceSetupState {
    switch event {
    case let .linkStateChanged(link):
        switch link {
        case .unpaired:
            // Every subscriber first hears .unpaired, which must not hide a failed start.
            return state == .failed ? .failed : .searching
        case .pairing, .searching:
            return .searching
        case .reconnecting:
            return .reconnecting
        case let .connected(latencyMs):
            return .connected(latencyMs: latencyMs)
        }

    case .linkFailed:
        return .failed

    case .tapDone, .tapBack:
        return state
    }
}
