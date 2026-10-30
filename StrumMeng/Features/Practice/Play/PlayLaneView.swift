import SwiftUI

/// What moves inside the lane: orange rail, hit ring on the left and nodes scrolling in from the right.
/// The lane itself (teal border, dark inside) is part of the Play_BG artwork. Layer order matches the
/// hi-fi: the ring's dark centre sits under the nodes, its stroke and the hit wave over them. Drawn in
/// screen coordinates from PlayScreenLayout, so it lines up with the artwork and the overlays.
struct PlayLaneView: View {
    let model: PlayScreenModel
    let layout: PlayScreenLayout

    var body: some View {
        let lane = layout.laneRect
        let laneTime = PlayTimeline.laneTime(songTime: model.songTime, readyLead: layout.readyLeadTime)
        let railY = layout.railY - lane.minY
        let hitX = layout.hitX - lane.minX

        ZStack(alignment: .topLeading) {
            Color.clear

            Rectangle()
                .fill(AppColor.track)
                .frame(width: lane.width, height: layout.trackThickness)
                .position(x: lane.width / 2, y: railY)

            Circle()
                .fill(AppColor.laneBackground)
                .frame(width: layout.ringSize, height: layout.ringSize)
                .position(x: hitX, y: railY)

            ForEach(visibleNodes(laneTime: laneTime)) { node in
                let x = nodeX(node, laneTime: laneTime) - lane.minX
                let look = HitAnimation.node(judgement: node.judgement, songTime: model.songTime)
                nodeView(node, look: look)
                    .position(x: look.snapsToRing ? hitX : x, y: railY)
                Text(node.countLabel)
                    .font(AppFont.mono(layout.labelFontSize))
                    .foregroundStyle(AppColor.laneLabel.opacity(node.arrow == nil ? 0.5 : 1))
                    .position(x: x, y: railY + layout.labelOffset)
            }

            HitRingView(size: layout.ringSize, judgement: model.lastJudgement,
                        strength: HitAnimation.ringStrength(judgement: model.lastJudgement,
                                                            songTime: model.songTime),
                        lineScale: HitAnimation.ringLineScale(lastStrumTime: model.lastStrumTime,
                                                              songTime: model.songTime))
                .position(x: hitX, y: railY)

            HitWaveView(judgement: model.lastJudgement, songTime: model.songTime, ringSize: layout.ringSize)
                .position(x: hitX, y: railY)
        }
        .frame(width: lane.width, height: lane.height)
        .clipShape(RoundedRectangle(cornerRadius: layout.laneCornerRadius))
    }

    @ViewBuilder
    private func nodeView(_ node: PlayLaneNode, look: NodeHitAppearance) -> some View {
        if let arrow = node.arrow {
            BeatNodeView(arrow: arrow, size: layout.nodeSize)
                .saturation(look.greyedOut ? 0 : 1)
                .scaleEffect(look.scale)
                .opacity(look.opacity)
        }
    }

    private func nodeX(_ node: PlayLaneNode, laneTime: TimeInterval) -> CGFloat {
        PlayTimeline.nodeX(nodeTime: node.time, songTime: laneTime, slotInterval: model.slotInterval,
                           hitX: layout.hitX, slotSpacing: layout.slotSpacing(slotInterval: model.slotInterval))
    }

    private func visibleNodes(laneTime: TimeInterval) -> [PlayLaneNode] {
        let lane = layout.laneRect
        return model.nodes.filter { node in
            let x = nodeX(node, laneTime: laneTime)
            return x > lane.minX - layout.nodeSize && x < lane.maxX + layout.nodeSize
        }
    }
}
