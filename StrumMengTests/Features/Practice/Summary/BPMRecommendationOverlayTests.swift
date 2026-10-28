//
//  BPMRecommendationOverlayTests.swift
//  StrumMengTests
//
//  Created by Sharon Tan on 28/10/26.
//

import XCTest
import SwiftUI
@testable import StrumMeng

final class BPMRecommendationOverlayTests: XCTestCase {

    func test_overlayInitialization_setsPropertiesCorrectly() {
        let recommendation = RecommendedBPM(currentBPM: 70, targetBPM: 50, accuracy: 0.45, delta: -20)
        var keepTapped = false
        var startBPM: Int?

        let overlay = BPMRecommendationOverlay(
            recommendation: recommendation,
            offTempoCount: 7,
            onKeepPrevious: { keepTapped = true },
            onStartRecommended: { bpm in startBPM = bpm }
        )

        XCTAssertEqual(overlay.recommendation, recommendation)
        XCTAssertEqual(overlay.offTempoCount, 7)

        overlay.onKeepPrevious()
        XCTAssertTrue(keepTapped)

        overlay.onStartRecommended(50)
        XCTAssertEqual(startBPM, 50)
    }

    func test_overlay_handlesZeroOffTempo() {
        let recommendation = RecommendedBPM(currentBPM: 80, targetBPM: 90, accuracy: 0.95, delta: 10)
        let overlay = BPMRecommendationOverlay(
            recommendation: recommendation,
            offTempoCount: 0
        )

        XCTAssertEqual(overlay.recommendation.targetBPM, 90)
        XCTAssertEqual(overlay.offTempoCount, 0)
    }
}
