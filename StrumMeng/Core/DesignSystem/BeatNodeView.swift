import SwiftUI

/// Round strum node, drawn from the Play_Arrow_Down / Play_Arrow_Up artwork (red ↓, teal ↑).
/// Shared by Listen, Play and Replay.
struct BeatNodeView: View {
    enum Arrow: Equatable {
        case down, up
    }

    let arrow: Arrow
    let size: CGFloat

    var body: some View {
        Image(arrow == .down ? "Play_Arrow_Down" : "Play_Arrow_Up")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel(arrow == .down ? "Down strum" : "Up strum")
    }
}

#Preview("Down and up") {
    HStack(spacing: AppSpacing.l) {
        BeatNodeView(arrow: .down, size: 72)
        BeatNodeView(arrow: .up, size: 72)
    }
    .padding(AppSpacing.xl)
    .background(AppColor.ink)
}
