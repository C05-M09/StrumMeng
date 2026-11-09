/// Remembers whether the first-launch invitation has already led to device setup.
@MainActor
protocol PairingIntroductionStore: AnyObject {
    var hasShownIntroduction: Bool { get }
    func markIntroductionShown()
}
