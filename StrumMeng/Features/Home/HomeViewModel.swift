//
//  HomeViewModel.swift
//  StrumMeng
//
//  Created by rasyel on 29/10/26.
//

import Foundation
import Observation

/// The overlays that can sit on top of Home. Only one at a time.
enum HomeOverlay: Equatable {
    case option
    case guidebook
}

/// Turns Home button taps into navigation requests, and owns which overlay
/// (Option or Guidebook) is showing. Overlays are not routes, so they do not
/// go through the router. There is no reducer: each event maps straight to one
/// callback or one state change. Every tap that does something plays the button click; Showtime
/// does nothing, so it stays silent.
@MainActor
@Observable
final class HomeViewModel {
    let guidance: HomeGuidanceViewModel?
    private(set) var presentedOverlay: HomeOverlay?

    private let onPracticeRequested: () -> Void

    init(guidance: HomeGuidanceViewModel? = nil, onPracticeRequested: @escaping () -> Void) {
        self.guidance = guidance
        self.onPracticeRequested = onPracticeRequested
    }

    func send(_ event: HomeEvent) {
        switch event {
        // The buttons click on their own (ButtonPressSound), so no sound is played here.
        case .tapPractice:
            onPracticeRequested()
        case .tapOption:
            presentedOverlay = .option
        case .tapGuidebook:
            presentedOverlay = .guidebook
        case .dismissOverlay:
            presentedOverlay = nil
        case .tapShowtime:
            break   // Showtime is not connected yet: no navigation, no message.
        }
    }
}
