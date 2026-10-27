import XCTest
@testable import StrumMeng

final class PlayTimelineTests: XCTestCase {
    private let slot = PlayTimeline.slotInterval(bpm: 80)    // 0.375 s

    func test_slotInterval_isOneEighthNote() {
        XCTAssertEqual(PlayTimeline.slotInterval(bpm: 80), 0.375, accuracy: 1e-9)
        XCTAssertEqual(PlayTimeline.slotInterval(bpm: 120), 0.25, accuracy: 1e-9)
    }

    func test_nodeOnItsTime_sitsInTheHitRing() {
        let x = PlayTimeline.nodeX(nodeTime: 3, songTime: 3, slotInterval: slot, hitX: 100, slotSpacing: 200)
        XCTAssertEqual(x, 100, accuracy: 1e-9)
    }

    func test_nodeOneSlotAway_isOneSpacingToTheRight() {
        let x = PlayTimeline.nodeX(nodeTime: 3 + slot, songTime: 3, slotInterval: slot, hitX: 100, slotSpacing: 200)
        XCTAssertEqual(x, 300, accuracy: 1e-9)
    }

    func test_nodeAfterItsTime_hasMovedLeftOfTheRing() {
        let x = PlayTimeline.nodeX(nodeTime: 3, songTime: 3 + slot / 2, slotInterval: slot, hitX: 100, slotSpacing: 200)
        XCTAssertEqual(x, 0, accuracy: 1e-9)
    }

    func test_laneTime_holdsOnTheReadyLeadInThenFollowsSessionTime() {
        let lead = -PlayTimeline.readyLeadSlots * slot
        XCTAssertEqual(PlayTimeline.laneTime(songTime: -10, slotInterval: slot), lead, accuracy: 1e-9)
        XCTAssertEqual(PlayTimeline.laneTime(songTime: lead / 2, slotInterval: slot), lead / 2, accuracy: 1e-9)
        XCTAssertEqual(PlayTimeline.laneTime(songTime: 4, slotInterval: slot), 4, accuracy: 1e-9)
    }

    func test_makeNodes_repeatsThePatternWithCountLabels() {
        let nodes = PlayTimeline.makeNodes(pattern: [.down, nil, .down, .up, nil, .up, .down, .up],
                                           slotInterval: slot, duration: 60)
        XCTAssertEqual(nodes.count, 160)
        XCTAssertEqual(nodes[1].arrow, nil)
        XCTAssertEqual(nodes[11].arrow, .up)
        XCTAssertEqual(nodes.prefix(8).map(\.countLabel), ["1", "&", "2", "&", "3", "&", "4", "&"])
        XCTAssertEqual(nodes[2].time, 0.75, accuracy: 1e-9)
    }

    func test_makeNodes_withEmptyPattern_isEmpty() {
        XCTAssertTrue(PlayTimeline.makeNodes(pattern: [], slotInterval: slot, duration: 60).isEmpty)
    }

    func test_progress_isClampedToZeroAndOne() {
        XCTAssertEqual(PlayTimeline.progress(songTime: -2, duration: 60), 0)
        XCTAssertEqual(PlayTimeline.progress(songTime: 30, duration: 60), 0.5, accuracy: 1e-9)
        XCTAssertEqual(PlayTimeline.progress(songTime: 75, duration: 60), 1)
        XCTAssertEqual(PlayTimeline.progress(songTime: 5, duration: 0), 0)
    }

    func test_clockLabel_matchesTheHiFiFormat() {
        XCTAssertEqual(PlayTimeline.clockLabel(songTime: 3.7, duration: 60), "00:03 / 01:00")
        XCTAssertEqual(PlayTimeline.clockLabel(songTime: -1, duration: 60), "00:00 / 01:00")
        XCTAssertEqual(PlayTimeline.clockLabel(songTime: 90, duration: 60), "01:00 / 01:00")
    }

    func test_countIn_showsThreeTwoOneOnQuarterNotes() {
        let quarter = slot * 2
        XCTAssertEqual(PlayTimeline.countInNumber(songTime: -3 * quarter, slotInterval: slot), 3)
        XCTAssertEqual(PlayTimeline.countInNumber(songTime: -2.5 * quarter, slotInterval: slot), 3)
        XCTAssertEqual(PlayTimeline.countInNumber(songTime: -1.5 * quarter, slotInterval: slot), 2)
        XCTAssertEqual(PlayTimeline.countInNumber(songTime: -0.1, slotInterval: slot), 1)
        XCTAssertNil(PlayTimeline.countInNumber(songTime: 0, slotInterval: slot))
    }

    func test_countInBeatProgress_restartsOnEveryQuarter() {
        let quarter = slot * 2
        XCTAssertEqual(PlayTimeline.countInBeatProgress(songTime: -3 * quarter, slotInterval: slot), 0, accuracy: 1e-9)
        XCTAssertEqual(PlayTimeline.countInBeatProgress(songTime: -2.5 * quarter, slotInterval: slot), 0.5,
                       accuracy: 1e-9)
        XCTAssertEqual(PlayTimeline.countInBeatProgress(songTime: 1, slotInterval: slot), 1)
    }
}
