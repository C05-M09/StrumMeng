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

    func test_neighbouringNodes_neverOverlap() {
        for layout in [ipad13, ipad11] {
            XCTAssertLessThan(layout.nodeSize, layout.slotSpacing)
        }
    }

    func test_readyLeadIn_putsTheFirstNodeNearTheRightEdgeOfTheLane() {
        let slot = PlayTimeline.slotInterval(bpm: 80)
        let readyTime = PlayTimeline.laneTime(songTime: -10, slotInterval: slot)
        let x = PlayTimeline.nodeX(nodeTime: 0, songTime: readyTime, slotInterval: slot,
                                   hitX: ipad13.hitX, slotSpacing: ipad13.slotSpacing)
        XCTAssertGreaterThan(x, ipad13.laneRect.midX)
        XCTAssertLessThan(x, ipad13.laneRect.maxX)
    }
}
