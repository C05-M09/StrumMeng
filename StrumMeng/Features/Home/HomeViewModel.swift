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

    private let sounds: any MenuSoundService
    private let onPracticeRequested: () -> Void

    init(sounds: any MenuSoundService, guidance: HomeGuidanceViewModel? = nil,
         onPracticeRequested: @escaping () -> Void) {
        self.guidance = guidance
        self.sounds = sounds
        self.onPracticeRequested = onPracticeRequested
    }

    func send(_ event: HomeEvent) {
        switch event {
        case .tapPractice:
            sounds.playButtonSound()
            onPracticeRequested()
        case .tapOption:
            sounds.playButtonSound()
            presentedOverlay = .option
        case .tapGuidebook:
            sounds.playButtonSound()
            presentedOverlay = .guidebook
        case .dismissOverlay:
            // Sent by the Back button of Option and of Guidebook, so both click here.
            sounds.playButtonSound()
            presentedOverlay = nil
        case .tapShowtime:
            break   // Showtime is not connected yet: no navigation, no message.
        }
    }
}
