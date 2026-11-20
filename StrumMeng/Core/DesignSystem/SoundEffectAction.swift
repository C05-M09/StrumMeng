import SwiftUI

/// Lets a View play a UI sound without knowing the audio service, like SwiftUI's `openURL`.
///
/// Button clicks, the garage, page turns, pop-ups and wheel ticks are pure presentation: they
/// happen on press or when something appears, with no state for a view model to own. So instead
/// of passing the sound service into every view model, `AppContainer` puts one action in the
/// environment (ARCHITECTURE.md decision 25). The default is silent, which is what previews get.
/// The iPhone controller sets its own, which clicks only outside a session.
struct SoundEffectAction: Sendable {
    private let play: @MainActor @Sendable (SoundEffect) -> Void

    init(_ play: @escaping @MainActor @Sendable (SoundEffect) -> Void) {
        self.play = play
    }

    static let silent = SoundEffectAction { _ in }

    @MainActor
    func callAsFunction(_ effect: SoundEffect) {
        play(effect)
    }
}

extension EnvironmentValues {
    @Entry var playSoundEffect: SoundEffectAction = .silent
}
