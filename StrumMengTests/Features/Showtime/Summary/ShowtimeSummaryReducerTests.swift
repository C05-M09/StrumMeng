//
//  ShowtimeSummaryReducerTests.swift
//  StrumMeng
//
//  Created by Sharon Tan on 11/11/26.
//

import XCTest
@testable import StrumMeng

final class ShowtimeSummaryReducerTests: XCTestCase {

    private func makeSampleResult(accuracy: Double = 0.90, bpm: Int = 80, songID: String = "twinkle") -> SessionResult {
        SessionResult(
            id: UUID(),
            patternID: "foundation",
            songID: songID,
            bpm: bpm,
            accuracy: accuracy,
            perfectCount: 18,
            tooEarlyCount: 2,
            missCount: 0,
            createdAt: Date(),
            beatEvents: []
        )
    }

    func test_tapReplay_fromShowing_transitionsToNavigatingReplay() {
        let result = makeSampleResult()
        let initial = ShowtimeSummaryState.showing(result)

        let next = reduce(initial, .tapReplay)

        XCTAssertEqual(next, .navigating(.replay(result)))
    }

    func test_returnFromReplay_fromNavigatingReplay_transitionsBackToShowing() {
        let result = makeSampleResult()
        let initial = ShowtimeSummaryState.navigating(.replay(result))

        let next = reduce(initial, .returnFromReplay)

        XCTAssertEqual(next, .showing(result))
    }

    func test_tapRetry_fromShowing_transitionsDirectlyToNavigatingRetry() {
        let result = makeSampleResult()
        let initial = ShowtimeSummaryState.showing(result)

        let next = reduce(initial, .tapRetry)

        XCTAssertEqual(next, .navigating(.retry))
    }

    func test_tapBackToMain_fromShowing_transitionsToNavigatingBackToMain() {
        let result = makeSampleResult()
        let initial = ShowtimeSummaryState.showing(result)

        let next = reduce(initial, .tapBackToMain)

        XCTAssertEqual(next, .navigating(.backToMain))
    }

    func test_illegalTransitions_leaveStateUnchanged() {
        let navigatingRetry = ShowtimeSummaryState.navigating(.retry)
        XCTAssertEqual(reduce(navigatingRetry, .tapRetry), navigatingRetry)
        XCTAssertEqual(reduce(navigatingRetry, .tapReplay), navigatingRetry)
        XCTAssertEqual(reduce(navigatingRetry, .tapBackToMain), navigatingRetry)
        XCTAssertEqual(reduce(navigatingRetry, .returnFromReplay), navigatingRetry)

        let navigatingBack = ShowtimeSummaryState.navigating(.backToMain)
        XCTAssertEqual(reduce(navigatingBack, .tapRetry), navigatingBack)
        XCTAssertEqual(reduce(navigatingBack, .tapReplay), navigatingBack)
        XCTAssertEqual(reduce(navigatingBack, .tapBackToMain), navigatingBack)
        XCTAssertEqual(reduce(navigatingBack, .returnFromReplay), navigatingBack)

        let result = makeSampleResult()
        let showing = ShowtimeSummaryState.showing(result)
        XCTAssertEqual(reduce(showing, .returnFromReplay), showing)
    }
}

