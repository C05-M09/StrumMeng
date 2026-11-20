//
//  ShowtimeSummaryFeedbackContentTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import XCTest
@testable import StrumMeng

final class ShowtimeSummaryFeedbackContentTests: XCTestCase {

    private func makeResult(
        songID: String? = "twinkle_star",
        accuracy: Double,
        perfectCount: Int = 18,
        tooEarlyCount: Int = 2,
        missCount: Int = 0
    ) -> SessionResult {
        SessionResult(
            id: UUID(),
            patternID: "foundation",
            songID: songID,
            bpm: 96,
            accuracy: accuracy,
            perfectCount: perfectCount,
            tooEarlyCount: tooEarlyCount,
            missCount: missCount,
            createdAt: Date(),
            beatEvents: []
        )
    }

    func test_threeStars_showsAwesomeHeadlineAndPurfectMascot() {
        let content = ShowtimeSummaryFeedbackContent(result: makeResult(accuracy: 0.92))

        XCTAssertEqual(content.stars, 3)
        XCTAssertEqual(content.headline, "AWESOME!")
        XCTAssertEqual(content.characterImageName, "cat_purfect")
    }

    func test_twoStars_showsNiceHeadlineAndOkeMascot() {
        let content = ShowtimeSummaryFeedbackContent(result: makeResult(accuracy: 0.75))

        XCTAssertEqual(content.stars, 2)
        XCTAssertEqual(content.headline, "NICE!!")
        XCTAssertEqual(content.characterImageName, "cat_oke")
    }

    func test_zeroOrOneStar_showsYouGoodHeadlineAndMascot() {
        let contentOne = ShowtimeSummaryFeedbackContent(result: makeResult(accuracy: 0.55))
        XCTAssertEqual(contentOne.stars, 1)
        XCTAssertEqual(contentOne.headline, "YOU GOOD?")
        XCTAssertEqual(contentOne.characterImageName, "cat_you good")

        let contentZero = ShowtimeSummaryFeedbackContent(result: makeResult(accuracy: 0.40))
        XCTAssertEqual(contentZero.stars, 0)
        XCTAssertEqual(contentZero.headline, "YOU GOOD?")
        XCTAssertEqual(contentZero.characterImageName, "cat_you good")
    }

    func test_songInfoFallback_formatsSongIDCleanly() {
        let result = makeResult(songID: "twinkle_star", accuracy: 0.90)
        let info = ShowtimeSongInfo.fallback(for: result)

        XCTAssertEqual(info.title, "Twinkle Star")
        XCTAssertEqual(info.chordsLabel, "C  G  Am  F")
    }
}

