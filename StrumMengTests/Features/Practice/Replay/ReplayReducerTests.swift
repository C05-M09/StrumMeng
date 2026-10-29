//
//  ReplayReducerTests.swift
//  StrumMengTests
//
//  Created by Sharon Tan on 29/10/26.
//

import XCTest
@testable import StrumMeng

final class ReplayReducerTests: XCTestCase {
    func test_play_fromReady_transitionsToPlaying() {
        XCTAssertEqual(reduce(ReplayState.ready, .play), .playing)
    }

    func test_pause_fromPlaying_transitionsToPaused() {
        XCTAssertEqual(reduce(ReplayState.playing, .pause), .paused)
    }

    func test_play_fromPaused_resumesPlaying() {
        XCTAssertEqual(reduce(ReplayState.paused, .play), .playing)
    }

    func test_finish_fromPlaying_transitionsToFinished() {
        XCTAssertEqual(reduce(ReplayState.playing, .finish), .finished)
    }

    func test_restart_fromPausedOrFinishedOrPlaying_transitionsToPlaying() {
        XCTAssertEqual(reduce(ReplayState.paused, .restart), .playing)
        XCTAssertEqual(reduce(ReplayState.finished, .restart), .playing)
        XCTAssertEqual(reduce(ReplayState.playing, .restart), .playing)
    }

    func test_play_fromFinished_restartsPlaying() {
        XCTAssertEqual(reduce(ReplayState.finished, .play), .playing)
    }

    func test_backToSummary_fromAnyState_transitionsToDismissed() {
        XCTAssertEqual(reduce(ReplayState.ready, .backToSummary), .dismissed)
        XCTAssertEqual(reduce(ReplayState.playing, .backToSummary), .dismissed)
        XCTAssertEqual(reduce(ReplayState.paused, .backToSummary), .dismissed)
        XCTAssertEqual(reduce(ReplayState.finished, .backToSummary), .dismissed)
    }

    func test_illegalTransitions_leaveStateUnchanged() {
        XCTAssertEqual(reduce(ReplayState.ready, .pause), .ready)
        XCTAssertEqual(reduce(ReplayState.ready, .finish), .ready)
        XCTAssertEqual(reduce(ReplayState.paused, .pause), .paused)
        XCTAssertEqual(reduce(ReplayState.paused, .finish), .paused)
        XCTAssertEqual(reduce(ReplayState.finished, .pause), .finished)
        XCTAssertEqual(reduce(ReplayState.finished, .finish), .finished)
        XCTAssertEqual(reduce(ReplayState.dismissed, .play), .dismissed)
    }
}
