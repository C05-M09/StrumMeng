import XCTest
@testable import StrumMeng

final class TimingJudgeTests: XCTestCase {
    private let step80 = AudioBeatClock.stepInterval(bpm: 80)     // 0.375 s, windows not capped
    private let down = BeatTarget(index: 4, expectedTime: 10.0, direction: .down)

    private func judge(_ strums: [StrumEvent], target: BeatTarget? = nil,
                       offset: TimeInterval = 0) -> TimingJudgement {
        TimingJudge.judge(target: target ?? down, strums: strums, latencyOffset: offset, stepInterval: step80,
                          config: .standard)
    }

    // MARK: Timing

    func test_strumOnTheBeat_isPerfect() {
        let judgement = judge([PracticeFixtures.strum(at: 10.0)])
        XCTAssertEqual(judgement.event.result, .perfect)
        XCTAssertEqual(judgement.event.stepIndex, 4)
        XCTAssertEqual(judgement.event.offsetMs ?? .nan, 0, accuracy: 1e-6)
        XCTAssertNotNil(judgement.strumID)
    }

    func test_strumSlightlyLateInsidePerfectWindow_isPerfect() {
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.045)]).event.result, .perfect)
    }

    func test_strumSlightlyEarlyInsidePerfectWindow_isPerfect() {
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 9.955)]).event.result, .perfect)
    }

    func test_strumBeforePerfectWindow_isTooEarly_withNegativeOffset() {
        let event = judge([PracticeFixtures.strum(at: 9.9)]).event
        XCTAssertEqual(event.result, .tooEarly)
        XCTAssertEqual(event.offsetMs ?? .nan, -100, accuracy: 1e-6)
    }

    func test_strumBeforeEarlyWindow_isMissAndNotUsed() {
        let judgement = judge([PracticeFixtures.strum(at: 9.8)])
        XCTAssertEqual(judgement.event.result, .miss)
        XCTAssertNil(judgement.event.offsetMs)
        XCTAssertNil(judgement.strumID)
    }

    func test_noStrum_isMiss() {
        XCTAssertEqual(judge([]).event.result, .miss)
    }

    func test_lateStrum_isJudgedAsMiss() {
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.06)]).event.result, .miss)
    }

    func test_doubleStrum_earlyThenPerfect_countsAsPerfect() {
        let perfect = PracticeFixtures.strum(at: 10.02)
        let judgement = judge([PracticeFixtures.strum(at: 9.9), perfect])
        XCTAssertEqual(judgement.event.result, .perfect)
        XCTAssertEqual(judgement.strumID, perfect.id)
    }

    func test_twoPerfectStrums_theFirstOneCounts_asItWouldLive() {
        let first = PracticeFixtures.strum(at: 9.97)
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.005), first]).strumID, first.id)
    }

    func test_positiveLatencyOffset_movesStrumsEarlier() {
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.1)], offset: 0.1).event.result, .perfect)
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.0)], offset: 0.1).event.result, .tooEarly)
    }

    func test_negativeLatencyOffset_movesStrumsLater() {
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 9.9)], offset: -0.1).event.result, .perfect)
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.0)], offset: -0.1).event.result, .miss)
    }

    // MARK: Direction

    func test_upStepNeedsAnUpStrum() {
        let up = BeatTarget(index: 1, expectedTime: 10.0, direction: .up)
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.0, .up)], target: up).event.result, .perfect)
        XCTAssertEqual(judge([PracticeFixtures.strum(at: 10.0, .down)], target: up).event.result, .miss)
    }

    func test_wrongDirectionOnTime_isMiss_butKeepsItsOffset() {
        let judgement = judge([PracticeFixtures.strum(at: 10.01, .up)])
        XCTAssertEqual(judgement.event.result, .miss)
        XCTAssertEqual(judgement.event.offsetMs ?? .nan, 10, accuracy: 1e-6)
        XCTAssertNotNil(judgement.strumID)
    }

    func test_wrongDirectionThenRightDirection_staysMiss() {
        let strums = [PracticeFixtures.strum(at: 9.92, .up), PracticeFixtures.strum(at: 10.0, .down)]
        XCTAssertEqual(judge(strums).event.result, .miss)
    }

    func test_tooEarlyThenWrongDirection_becomesMiss() {
        let strums = [PracticeFixtures.strum(at: 9.88, .down), PracticeFixtures.strum(at: 9.92, .up)]
        XCTAssertEqual(judge(strums).event.result, .miss)
    }

    func test_perfectThenWrongDirection_staysPerfect() {
        let strums = [PracticeFixtures.strum(at: 10.0, .down), PracticeFixtures.strum(at: 10.03, .up)]
        XCTAssertEqual(judge(strums).event.result, .perfect)
    }

    func test_wrongDirectionOutsideTheWindow_isIgnored() {
        let strums = [PracticeFixtures.strum(at: 9.7, .up), PracticeFixtures.strum(at: 10.0, .down)]
        XCTAssertEqual(judge(strums).event.result, .perfect)
    }

    // MARK: Helpers

    func test_decides_isTrueForPerfectOrWrongDirection_only() {
        func decides(_ time: TimeInterval, _ direction: StrumDirection) -> Bool {
            TimingJudge.decides(PracticeFixtures.strum(at: time, direction), for: down, latencyOffset: 0,
                                stepInterval: step80, config: .standard)
        }
        XCTAssertTrue(decides(10.04, .down))      // Perfect
        XCTAssertFalse(decides(9.9, .down))       // Too Early, could still improve
        XCTAssertTrue(decides(9.9, .up))          // wrong direction in the window
        XCTAssertFalse(decides(9.7, .up))         // outside the window
    }

    func test_windowEnd_isBeatPlusPerfectWindowPlusOffset() {
        let end = TimingJudge.windowEnd(of: down, latencyOffset: 0.1, stepInterval: step80, config: .standard)
        XCTAssertEqual(end, 10.15, accuracy: 1e-9)
    }
}
