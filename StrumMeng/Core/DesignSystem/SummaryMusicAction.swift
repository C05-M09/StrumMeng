import SwiftUI

/// Lets a summary screen ask for the menu music without knowing the audio service, like
/// `SoundEffectAction`.
///
/// The route alone cannot tell when a summary is showing: Replay slides over the summary inside the
/// same route, and the Showtime summary lives inside the `.showtime` route next to Listen and Play.
/// So the summary views say it themselves: `true` while the summary is on screen, `false` while
/// Replay is open and once the summary goes away. `AppContainer` passes it to `MenuMusicPolicy`.
/// The default does nothing, which is what previews get.
struct SummaryMusicAction: Sendable {
    private let set: @MainActor @Sendable (Bool) -> Void

    init(_ set: @escaping @MainActor @Sendable (Bool) -> Void) {
        self.set = set
    }

    static let none = SummaryMusicAction { _ in }

    @MainActor
    func callAsFunction(_ isShowingSummary: Bool) {
        set(isShowingSummary)
    }
}

extension EnvironmentValues {
    @Entry var setSummaryMusic: SummaryMusicAction = .none
}
