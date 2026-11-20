import Foundation
import Observation

/// Which full-screen card is covering Home. Nil means none (Home is clear).
enum HomeOverlay: Equatable {
    case option
    case guidebook
}

/// Turns Home button taps into navigation requests, and owns which overlay
/// (Option or Guidebook) is showing. Overlays are not routes, so they do not
/// go through the router. There is no reducer: each event maps straight to one
/// callback or one state change. ButtonPressSound on the View handles button audio.
@MainActor
@Observable
final class HomeViewModel {
    let guidance: HomeGuidanceViewModel?
    private(set) var presentedOverlay: HomeOverlay?

    private let onPracticeRequested: () -> Void
    private let onShowtimeRequested: () -> Void

    init(guidance: HomeGuidanceViewModel? = nil,
         onPracticeRequested: @escaping () -> Void,
         onShowtimeRequested: @escaping () -> Void = {}) {
        self.guidance = guidance
        self.onPracticeRequested = onPracticeRequested
        self.onShowtimeRequested = onShowtimeRequested
    }

    func send(_ event: HomeEvent) {
        switch event {
        case .tapPractice:
            onPracticeRequested()
        case .tapOption:
            presentedOverlay = .option
        case .tapGuidebook:
            presentedOverlay = .guidebook
        case .tapShowtime:
            onShowtimeRequested()
        case .dismissOverlay:
            presentedOverlay = nil
        }
    }
}
