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
/// callback or one state change.
@MainActor
@Observable
final class HomeViewModel {
    private(set) var presentedOverlay: HomeOverlay?

    private let onPracticeRequested: () -> Void

    init(onPracticeRequested: @escaping () -> Void) {
        self.onPracticeRequested = onPracticeRequested
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
            presentedOverlay = nil
        case .tapShowtime:
            break   // Showtime is not connected yet: no navigation, no message.
        }
    }
}
