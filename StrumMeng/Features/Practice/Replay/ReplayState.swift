//
//  ReplayState.swift
//  StrumMeng
//
//  Created by Sharon Tan on 29/10/26.
//

import Foundation

/// Possible states of the Replay screen.
enum ReplayState: Equatable, Sendable {
    /// Screen is loaded and waiting for user to start playback.
    case ready
    /// Playback is actively running.
    case playing
    /// Playback is temporarily paused.
    case paused
    /// Playback reached the end of the session.
    case finished
    /// User dismissed replay to return to Summary.
    case dismissed
}
