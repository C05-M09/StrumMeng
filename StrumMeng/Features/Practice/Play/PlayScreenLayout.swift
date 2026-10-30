import CoreGraphics
import Foundation

/// Every position on the Play screen, measured on the `Play_BG` artwork (1376 x 1032 pt) and mapped
/// to the real screen. The artwork is stretched to fill the screen, so x follows the width and y the
/// height; round things (buttons, nodes, ring) use the smaller of the two scales so they stay round.
/// Pure geometry, no SwiftUI.
struct PlayScreenLayout: Equatable {
    static let designSize = CGSize(width: 1376, height: 1032)
    /// Lane scroll speed in node widths per second, from the prototype (320 pt/s for a 76 pt node at
    /// 1× note scale; both grow with the scale). The speed stays the same at every BPM, so nodes sit
    /// closer together at faster tempos instead of rushing past.
    static let scrollSpeedInNodes: CGFloat = 320.0 / 76.0
    /// Where the first node waits on READY?, as a fraction of the lane width (right of the text).
    static let readyNodeLaneFraction: CGFloat = 0.87

    /// Design points -> screen points for sizes that must keep their shape.
    let unit: CGFloat
    let size: CGSize

    // Header (the wooden box is part of Play_BG; only the text and buttons are drawn)
    let pauseCenter: CGPoint
    let pauseSize: CGFloat
    let titleCenter: CGPoint
    let titleMaxWidth: CGFloat
    let titleFontSize: CGFloat
    let bpmFontSize: CGFloat
    let bpmTrailing: CGFloat
    let bpmCenterY: CGFloat

    // Board (frame, panel and lane are part of Play_BG)
    /// The dark area inside the teal border, where the nodes travel.
    let laneRect: CGRect
    let laneCornerRadius: CGFloat
    let clockLabelTop: CGFloat
    let clockFontSize: CGFloat
    let progressRect: CGRect

    // Lane contents, in screen coordinates
    let railY: CGFloat
    let hitX: CGFloat
    let nodeSize: CGFloat
    let ringSize: CGFloat
    let trackThickness: CGFloat
    let labelOffset: CGFloat
    let labelFontSize: CGFloat

    init(size: CGSize) {
        self.size = size
        let sx = size.width / Self.designSize.width
        let sy = size.height / Self.designSize.height
        let u = min(sx, sy)
        unit = u

        pauseCenter = CGPoint(x: 106 * sx, y: 104 * sy)
        pauseSize = 86 * u
        titleCenter = CGPoint(x: 690 * sx, y: 100 * sy)
        titleMaxWidth = 640 * u               // scales with the font, so titles wrap the same on every iPad
        titleFontSize = 60 * u
        bpmFontSize = 42 * u
        bpmTrailing = 71 * sx
        bpmCenterY = 104 * sy

        laneRect = CGRect(x: 120 * sx, y: 309 * sy, width: 1140 * sx, height: 474 * sy)
        laneCornerRadius = 16 * u
        clockLabelTop = 836 * sy
        clockFontSize = 24 * u
        progressRect = CGRect(x: 120 * sx, y: 878 * sy, width: 1140 * sx, height: 32 * u)

        // Inside the lane, proportions follow the lane so they hold on any screen.
        railY = laneRect.minY + laneRect.height * 0.467
        hitX = laneRect.minX + laneRect.width * 0.115
        // About 190 pt on a 13-inch iPad: the prototype at note scale 2.5.
        nodeSize = laneRect.height * 0.4
        ringSize = nodeSize * 1.35
        trackThickness = nodeSize * 0.25
        labelOffset = nodeSize * 0.9
        labelFontSize = nodeSize * 0.22
    }

    /// The pause button's touch area (the artwork is 88.46 x 95.85, so slightly taller than wide).
    var pauseRect: CGRect {
        let height = pauseSize * 95.85 / 88.46
        return CGRect(x: pauseCenter.x - pauseSize / 2, y: pauseCenter.y - height / 2,
                      width: pauseSize, height: height)
    }

    /// Distance between neighbouring nodes (one step apart) at a given step length. Nodes move at a
    /// fixed speed, so this grows at slow tempos and shrinks at fast ones.
    func slotSpacing(slotInterval: TimeInterval) -> CGFloat {
        scrollSpeed * CGFloat(slotInterval)
    }

    /// Nodes' speed across the screen, in points per second.
    var scrollSpeed: CGFloat {
        nodeSize * Self.scrollSpeedInNodes
    }

    /// How long before the ring the first node waits on READY?, so it sits near the right edge of
    /// the lane on any screen and at any tempo.
    var readyLeadTime: TimeInterval {
        let readyX = laneRect.minX + laneRect.width * Self.readyNodeLaneFraction
        return TimeInterval((readyX - hitX) / scrollSpeed)
    }

    /// Where the READY? text and the count-in numbers sit: centre of the lane, on the rail.
    var calloutCenter: CGPoint { CGPoint(x: laneRect.midX, y: railY) }
}
