import SwiftUI

/// Shared header for Gameplay (`PracticePlayView`) and Replay (`ReplayView`), matching
/// `ListenView`'s metrics (font size, line spacing, outline width, shadow, and positions).
struct PlayScreenHeader: View {
    let layout: PlayScreenLayout
    let model: PlayScreenModel
    var titleFontScale: CGFloat = 1
    var titleLineSpacing: CGFloat? = nil
    var bpmColor: Color? = nil
    let onPause: () -> Void

    var body: some View {
        let u = layout.unit
        let lines = model.titleLines ?? TitleLineWrapping.headerLines(for: model.title)
        let spacing = titleLineSpacing.map { $0 * u } ?? layout.titleLineSpacing

        ZStack(alignment: .topLeading) {
            Button("Pause", action: onPause)
                .buttonStyle(AssetButtonStyle(
                    normalAssetName: "Button_Pause_Normal",
                    pressedAssetName: "Button_Pause_Pressed",
                    size: CGSize(width: 90 * u, height: 98 * u)
                ))
                .accessibilityLabel("Pause")
                .position(layout.pauseCenter)

            VStack(spacing: spacing) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    OutlinedText(
                        text: line.uppercased(),
                        font: AppFont.display(layout.titleFontSize * titleFontScale),
                        foregroundColor: AppColors.white,
                        outlineColor: AppColors.brownInk,
                        outlineWidth: layout.titleOutlineWidth * titleFontScale,
                        shadowColor: AppColors.brownInk,
                        shadowOffset: .zero,
                        alignment: .center
                    )
                }
            }
            .minimumScaleFactor(0.5)
            .frame(maxWidth: layout.titleMaxWidth)
            .position(layout.titleCenter)

            Text("BPM \(model.bpm)")
                .font(AppFont.mono(layout.bpmFontSize))
                .foregroundStyle(bpmColor ?? AppColor.ink)
                .fixedSize()
                .position(layout.bpmCenter)
        }
    }
}
