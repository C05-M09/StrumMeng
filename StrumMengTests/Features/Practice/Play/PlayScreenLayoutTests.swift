import XCTest
@testable import StrumMeng

final class PlayScreenLayoutTests: XCTestCase {
    private let ipad13 = PlayScreenLayout(size: CGSize(width: 1376, height: 1032))   // 4:3, like the hi-fi
    private let ipad11 = PlayScreenLayout(size: CGSize(width: 1180, height: 820))    // wider than 4:3

    func test_atDesignSize_unitIsOne() {
        XCTAssertEqual(PlayScreenLayout(size: PlayScreenLayout.designSize).unit, 1, accuracy: 1e-9)
    }

    func test_atDesignSize_theLaneMatchesTheDarkAreaOfPlayBG() {
        XCTAssertEqual(ipad13.laneRect, CGRect(x: 120, y: 309, width: 1140, height: 474))
    }

    func test_onAWiderScreen_positionsStretchWithTheArtwork() {
        XCTAssertEqual(ipad11.laneRect.minX / ipad11.size.width, ipad13.laneRect.minX / ipad13.size.width,
                       accuracy: 1e-9)
        XCTAssertEqual(ipad11.laneRect.minY / ipad11.size.height, ipad13.laneRect.minY / ipad13.size.height,
                       accuracy: 1e-9)
        XCTAssertEqual(ipad11.titleCenter.x / ipad11.size.width, ipad13.titleCenter.x / ipad13.size.width,
                       accuracy: 1e-9)
    }

    func test_clockAndProgress_sitBelowTheLaneInsideTheScreen() {
        for layout in [ipad13, ipad11] {
            XCTAssertLessThan(layout.laneRect.maxY, layout.clockLabelTop)
            XCTAssertLessThan(layout.clockLabelTop, layout.progressRect.minY)
            XCTAssertLessThan(layout.progressRect.maxY, layout.size.height)
        }
    }

    func test_hitRingAndRail_sitInsideTheLane() {
        for layout in [ipad13, ipad11] {
            XCTAssertGreaterThan(layout.hitX - layout.ringSize / 2, layout.laneRect.minX)
            XCTAssertGreaterThan(layout.railY, layout.laneRect.minY)
            XCTAssertLessThan(layout.railY + layout.labelOffset, layout.laneRect.maxY)
        }
    }

    func test_neighbouringNodes_neverOverlap_evenAtTheFastestTempo() {
        let fastest = PlayTimeline.slotInterval(bpm: PracticeTempoConfig.maximumBPM)
        for layout in [ipad13, ipad11] {
            XCTAssertLessThan(layout.nodeSize, layout.slotSpacing(slotInterval: fastest))
        }
    }

    func test_nodes_scrollAtTheSameSpeedAtEveryTempo() {
        let slow = PlayTimeline.slotInterval(bpm: 60)
        let fast = PlayTimeline.slotInterval(bpm: 120)
        let slowSpeed = ipad13.slotSpacing(slotInterval: slow) / CGFloat(slow)
        let fastSpeed = ipad13.slotSpacing(slotInterval: fast) / CGFloat(fast)
        XCTAssertEqual(slowSpeed, fastSpeed, accuracy: 1e-6)
    }

    func test_nodeSizeAndSpeed_matchThePrototypeAtNoteScale2Point5OnA13InchIPad() {
        // Prototype at note scale 2.5: 190 pt nodes moving at 800 pt/s.
        XCTAssertEqual(ipad13.nodeSize, 190, accuracy: 1)
        XCTAssertEqual(ipad13.scrollSpeed, 800, accuracy: 5)
    }

    func test_nodeRingAndLabel_fitInsideTheLane() {
        for layout in [ipad13, ipad11] {
            XCTAssertGreaterThan(layout.railY - layout.ringSize / 2, layout.laneRect.minY)
            XCTAssertLessThan(layout.railY + layout.ringSize / 2, layout.laneRect.maxY)
            XCTAssertLessThan(layout.railY + layout.labelOffset + layout.labelFontSize, layout.laneRect.maxY)
        }
    }

    func test_readyLeadIn_putsTheFirstNodeInTheRightPartOfTheLane_atEveryTempo() {
        for layout in [ipad13, ipad11] {
            let readyTime = PlayTimeline.laneTime(songTime: -10, readyLead: layout.readyLeadTime)
            for bpm in [PracticeTempoConfig.minimumBPM, 80, PracticeTempoConfig.maximumBPM] {
                let slot = PlayTimeline.slotInterval(bpm: bpm)
                let x = PlayTimeline.nodeX(nodeTime: 0, songTime: readyTime, slotInterval: slot,
                                           hitX: layout.hitX, slotSpacing: layout.slotSpacing(slotInterval: slot))
                // Right of READY? (centred on the lane) and still inside the lane.
                XCTAssertGreaterThan(x - layout.nodeSize / 2, layout.laneRect.midX + layout.laneRect.width * 0.1)
                XCTAssertLessThan(x + layout.nodeSize / 2, layout.laneRect.maxX)
            }
        }
    }
}
