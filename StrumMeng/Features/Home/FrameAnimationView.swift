//
//  FrameAnimationView.swift
//  StrumMeng
//
//  Created by rasyel on 04/11/26.
//

import SwiftUI

/// Plays a numbered image sequence in a loop (`prefix` + 5-digit index, e.g. "..._00000").
/// The frame is picked from the clock, so the animation never drifts and costs nothing
/// when the view is off screen.
struct FrameAnimationView: View {
    let framePrefix: String
    let frameCount: Int
    let framesPerSecond: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            frameImage(at: 0)
        } else {
            TimelineView(.animation) { context in
                frameImage(at: Self.frameIndex(
                    at: context.date,
                    framesPerSecond: framesPerSecond,
                    frameCount: frameCount
                ))
            }
        }
    }

    private func frameImage(at index: Int) -> some View {
        Image(framePrefix + String(format: "%05d", index))
            .resizable()
            .scaledToFill()
    }

    /// Which frame to show at `date`, looping forever.
    static func frameIndex(at date: Date, framesPerSecond: Double, frameCount: Int) -> Int {
        guard frameCount > 0, framesPerSecond > 0 else { return 0 }
        let elapsed = date.timeIntervalSinceReferenceDate
        return Int(elapsed * framesPerSecond) % frameCount
    }
}
