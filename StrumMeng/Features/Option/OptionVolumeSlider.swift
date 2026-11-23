import SwiftUI

/// The volume slider drawn from the artwork: a white fill inside the brown track up to the pick, and
/// the guitar pick as the thumb. SwiftUI's Slider cannot take custom artwork, so this one handles the
/// drag itself and keeps VoiceOver's adjustable behaviour.
struct OptionVolumeSlider: View {
    let title: String
    @Binding var value: Double

    private let width = OptionCardLayout.sliderWidth
    private let thumb = OptionCardLayout.sliderThumbSize

    private let trackHeight = OptionCardLayout.sliderTrackHeight
    /// The pick stops at the centre of the track's rounded end, so it covers that end at 0 and full.
    private var endInset: CGFloat { trackHeight / 2 }

    var body: some View {
        let thumbX = OptionSliderGeometry.thumbCenterX(for: value, trackWidth: width, endInset: endInset)
        let inset = OptionCardLayout.sliderFillInset
        let fillWidth = max(thumbX - inset, 0)

        ZStack(alignment: .leading) {
            Image("Option_Slider_Track")
                .resizable()
                .frame(width: width, height: trackHeight)
            // The filled part, inside the outline from the left end to the pick's centre. Its right
            // end is always under the pick, and so is the bit left showing at 0.
            // The dark inner border makes the white read as sunk into the track, as in the design.
            Capsule()
                .fill(AppColors.white)
                .overlay(Capsule().strokeBorder(AppColors.brownInk,
                                                lineWidth: OptionCardLayout.sliderFillBorderWidth))
                .frame(width: fillWidth, height: trackHeight - inset * 2)
                .offset(x: inset)
            Image("Option_Slider_Thumb")
                .resizable()
                .frame(width: thumb.width, height: thumb.height)
                .offset(x: thumbX - thumb.width / 2)
        }
        // Laid out at the track's height so the taller pick does not push the rows apart; it hangs
        // over above and below. The touch area still covers the whole pick.
        .frame(width: width, height: trackHeight)
        .contentShape(Rectangle().inset(by: -(thumb.height - trackHeight) / 2))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let next = OptionSliderGeometry.value(atX: drag.location.x, trackWidth: width,
                                                          endInset: endInset)
                    // Only real changes, so a still finger does not keep saving the same volume.
                    if next != value { value = next }
                }
        )
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = OptionSliderGeometry.value(value, movedBy: 1)
            case .decrement: value = OptionSliderGeometry.value(value, movedBy: -1)
            @unknown default: break
            }
        }
    }
}
