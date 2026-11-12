import Foundation

/// The existing Practice engine is injected through this interface; chord synthesis is separate.
@MainActor
protocol SongGameplay: AnyObject {
    var state: PracticeState { get }
    var isControllerConnected: Bool { get }
    var isAnimating: Bool { get }
    var onStateChanged: ((PracticeState) -> Void)? { get set }
    var onConnectionChanged: ((Bool) -> Void)? { get set }
    func screenModel() -> PlayScreenModel
    func onAppear()
    func onDisappear() async
    func send(_ event: PracticeEvent) async
}
