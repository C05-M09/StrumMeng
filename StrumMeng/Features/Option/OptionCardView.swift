import SwiftUI

/// The Option card: the `Option_Card` artwork with a title and two volume sliders on top.
///
/// Fixed size (`OptionCardLayout.size`), so the screen places it with `.position`, like the Practice card.
/// The card only edits the two bindings; saving them is the view model's job.
struct OptionCardView: View {
    @Binding var soundVolume: Double
    @Binding var sfxVolume: Double

    var body: some View {
        // Everything is pinned to the top of the card, so nothing is centred or pushed down by spacers.
        ZStack(alignment: .top) {
            Image("Option_Card")
                .resizable()
                .scaledToFit()
                .frame(width: OptionCardLayout.size.width, height: OptionCardLayout.size.height)
//            OptionCardArt()

            if OptionCardLayout.drawsTitle {
                Text("OPTION")
                    .font(AppTypography.bungee(size: OptionCardLayout.titleFontSize))
                    .foregroundStyle(AppColors.brownInk)
                    .padding(.top, OptionCardLayout.titleTopPadding)
            }

            VStack(alignment: .leading, spacing: OptionCardLayout.rowSpacing) {
                OptionSliderRow(symbolName: "speaker.wave.2.fill", title: "Music", value: $soundVolume)
                OptionSliderRow(symbolName: "music.note", title: "Sound Effects", value: $sfxVolume)
            }
            .padding(.top, OptionCardLayout.rowsTopInset)
        }
        .frame(width: OptionCardLayout.size.width, height: OptionCardLayout.size.height, alignment: .top)
        .accessibilityElement(children: .contain)
    }
}

#Preview("Option card") {
    @Previewable @State var sound = 0.5
    @Previewable @State var sfx = 0.5

    OptionCardView(soundVolume: $sound, sfxVolume: $sfx)
        .padding(60)
}
