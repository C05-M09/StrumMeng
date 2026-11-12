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
/// callback or one state change. Button clicks are played by the buttons themselves, through the
/// `playSoundEffect` environment, so this view model plays no sound.
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
        case .dismissOverlay:
            // Sent by the Back button of Option and of Guidebook.
            presentedOverlay = nil
        case .tapShowtime:
            onShowtimeRequested()
        }
    }
}
