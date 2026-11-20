import SwiftUI

/// Pattern-only Listen, matching Practice. Chords belong to gameplay, not this lane.
struct ShowtimeListenView: View {
    let title: String
    let bpm: Int
    let pattern: StrumPattern
    let activeStep: Int
    let canReady: Bool
    let patternIndex: Int
    let patternCount: Int
    let onSelectPattern: (Int) -> Void
    let onReady: () -> Void
    let onPause: () -> Void

    var body: some View {
        ZStack {
            Image("Showtime_Assets/Showtime_BG").resizable()
            VStack(spacing: ShowtimeLayout.titleLineSpacing) {
                ForEach(Array(TitleLineWrapping.lines(for: title).enumerated()), id: \.offset) { _, line in
                    OutlinedText(text: line.uppercased(), font: AppTypography.bungee(size: ShowtimeLayout.titleSize),
                        foregroundColor: AppColors.white, outlineColor: AppColors.brownInk,
                        outlineWidth: 5, shadowColor: AppColors.brownInk, shadowOffset: .zero, alignment: .center)
                }
            }.frame(width: 790).position(x: 688, y: 100)
            Text("BPM \(bpm)").font(AppTypography.dmMono(size: 42))
                .foregroundStyle(AppColors.white).position(x: 1210, y: 105)
            Button("Pause", action: onPause)
                .buttonStyle(AssetButtonStyle(normalAssetName: "Button_Pause_Normal",
                    pressedAssetName: "Button_Pause_Pressed", size: CGSize(width: 90, height: 98)))
                .position(x: 110, y: 109)
            Rectangle().fill(AppColor.track).frame(width: 1140, height: 30)
                .position(x: 690, y: ShowtimeLayout.railY)
            ForEach(pattern.strokes.indices, id: \.self) { slot in slotView(slot) }
            if patternCount > 1 { patternSelector.position(ShowtimeLayout.patternSelectorCenter) }
            Button("Ready", action: onReady)
                .buttonStyle(AssetButtonStyle(normalAssetName: canReady ? "Button_Ready_Normal" : "Button_Ready_Disabled",
                    pressedAssetName: "Button_Ready_Pressed", size: ShowtimeLayout.readySize))
                .disabled(!canReady)
                .position(ShowtimeLayout.readyCenter)
        }
    }
    private var patternSelector: some View {
        HStack(spacing: AppSpacing.m) {
            Button { onSelectPattern(patternIndex - 1) } label: {
                Image(systemName: "chevron.left").padding(AppSpacing.m)
            }.disabled(patternIndex == 0).accessibilityLabel("Previous pattern")
            Text("Pattern \(patternIndex + 1) / \(patternCount)")
            Button { onSelectPattern(patternIndex + 1) } label: {
                Image(systemName: "chevron.right").padding(AppSpacing.m)
            }.disabled(patternIndex + 1 >= patternCount).accessibilityLabel("Next pattern")
        }
        .font(AppTypography.dmMono(size: 26))
        .foregroundStyle(AppColors.brownInk)
        // Shared style, so the arrows click and sink like every other button.
        .buttonStyle(PressableButtonStyle())
    }
    private func slotView(_ slot: Int) -> some View {
        let spacing = 1140 / CGFloat(max(1, pattern.strokes.count))
        let x = 120 + spacing * (CGFloat(slot) + 0.5)
        let stroke = pattern.strokes[slot]
        return ZStack {
            if stroke != .rest {
                Image(stroke == .down ? "Play_Arrow_Down" : "Play_Arrow_Up")
                    .resizable().scaledToFit().frame(width: ShowtimeLayout.node, height: ShowtimeLayout.node)
                    .position(x: x, y: ShowtimeLayout.railY)
            }
            Text(pattern.beatLabels.indices.contains(slot) ? pattern.beatLabels[slot] : PlayTimeline.countLabels[slot % 8])
                .font(AppTypography.dmMono(size: ShowtimeLayout.monoSize))
                .foregroundStyle(AppColors.cream).position(x: x, y: ShowtimeLayout.countY)
            if slot == activeStep {
                Circle().stroke(AppColors.perfect, lineWidth: 5)
                    .frame(width: ShowtimeLayout.ring, height: ShowtimeLayout.ring)
                    .position(x: x, y: ShowtimeLayout.railY)
            }
        }.allowsHitTesting(false)
    }
}
