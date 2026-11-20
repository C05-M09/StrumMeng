//
//  ShowtimeSummaryFeedbackContent.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import Foundation

/// Headline, mascot asset, and dynamic off-tempo feedback copy for a finished Showtime session,
/// shared by `ShowtimeSummaryFeedbackOverlay` and `ShowtimeSummaryView`.
struct ShowtimeSummaryFeedbackContent: Equatable, Sendable {
    let stars: Int
    let headline: String
    let characterImageName: String
    let message: String

    init(result: SessionResult) {
        let stars = StarRating.stars(for: result.accuracy)
        let offTempoCount = result.tooEarlyCount + result.missCount
        let extraStrumCount = result.extraStrumCount

        self.stars = stars

        switch stars {
        case 3:
            headline = "AWESOME!"
            characterImageName = "cat_purfect"

            if offTempoCount == 0 {
                message = "FLAWLESS SHOWTIME! 0 OFF-TEMPO BEATS. WATCH REPLAY OR HIT RETRY FOR AN ENCORE!"
            } else if result.tooEarlyCount > result.missCount {
                message = "AWESOME RUN! ONLY \(Self.plural(result.tooEarlyCount, "EARLY STRUM")). CHECK REPLAY OR RETRY FOR A CLEAN SWEEP!"
            } else {
                message = "AWESOME PERFORMANCE! ONLY \(Self.plural(offTempoCount, "OFF-TEMPO BEAT")). WATCH REPLAY OR RETRY!"
            }

        case 2:
            headline = "NICE!!"
            characterImageName = "cat_oke"

            if result.tooEarlyCount > result.missCount {
                message = "CLOSE TIMING! RUSHED \(Self.plural(result.tooEarlyCount, "STRUM")). WATCH REPLAY AND RETRY ON BEAT!"
            } else if extraStrumCount > 0 && result.missCount >= result.tooEarlyCount {
                message = "ALMOST THERE! AVOID EXTRA STRUMS. CHECK REPLAY, THEN RETRY TO LOCK IT IN!"
            } else {
                message = "GOOD JOB! \(Self.plural(offTempoCount, "OFF-TEMPO BEAT")). CHECK REPLAY AND RETRY FOR 3 STARS!"
            }

        default:
            headline = "YOU GOOD?"
            characterImageName = "cat_you good"

            if result.perfectCount == 0 {
                message = "TOUGH TAKE! NO PERFECT HITS YET. WATCH REPLAY AND TAP RETRY TO TRY AGAIN!"
            } else if result.tooEarlyCount > result.missCount {
                message = "HOLD YOUR PAWS! RUSHED \(Self.plural(result.tooEarlyCount, "TIME")). CHECK REPLAY, THEN RETRY ON BEAT!"
            } else if extraStrumCount > 0 {
                message = "TOO MANY EXTRA STRUMS! WATCH REPLAY TO HEAR IT, THEN TAP RETRY!"
            } else {
                message = "OFF TEMPO ON \(Self.plural(offTempoCount, "BEAT")). WATCH REPLAY TO SPOT MISSES, THEN TAP RETRY!"
            }
        }
    }

    private static func plural(_ count: Int, _ singular: String) -> String {
        count == 1 ? "1 \(singular)" : "\(count) \(singular)S"
    }
}

