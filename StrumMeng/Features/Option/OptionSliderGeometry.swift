import CoreGraphics

/// Maps between a volume and where the pick sits on the Option slider.
///
/// The pick's centre travels from `endInset` in from the left end of the track to `endInset` in from
/// the right end. The slider uses the centre of the track's rounded end (half the track's height):
/// the pick narrows towards its tip, and stopping any earlier lets the rounded end peek out beside it
/// at 0 and at full volume. The fill ends at the pick's centre, so its edge is always under the pick.
enum OptionSliderGeometry {
    /// The volume for a touch at `x` (in the track's own coordinates), snapped to `VolumeConfig.step`.
    /// Touches beyond either end give the minimum or maximum.
    static func value(atX x: CGFloat, trackWidth: CGFloat, endInset: CGFloat) -> Double {
        let travel = trackWidth - endInset * 2
        guard travel > 0 else { return VolumeConfig.minimum }
        let fraction = Double((x - endInset) / travel)
        let raw = VolumeConfig.minimum + fraction * (VolumeConfig.maximum - VolumeConfig.minimum)
        return snapped(raw)
    }

    /// The x of the pick's centre for a volume, in the track's own coordinates. The white fill runs
    /// from the left end to here; the brown track shows from here to the right end.
    static func thumbCenterX(for value: Double, trackWidth: CGFloat, endInset: CGFloat) -> CGFloat {
        let span = VolumeConfig.maximum - VolumeConfig.minimum
        guard span > 0 else { return endInset }
        let fraction = (VolumeConfig.clamped(value) - VolumeConfig.minimum) / span
        return endInset + CGFloat(fraction) * max(trackWidth - endInset * 2, 0)
    }

    /// The volume one step up (`steps` > 0) or down (`steps` < 0), for VoiceOver's swipe up / down.
    static func value(_ value: Double, movedBy steps: Int) -> Double {
        snapped(value + Double(steps) * VolumeConfig.step)
    }

    /// Rounds to the nearest step and keeps the result inside the range.
    static func snapped(_ value: Double) -> Double {
        let clamped = VolumeConfig.clamped(value)
        let steps = ((clamped - VolumeConfig.minimum) / VolumeConfig.step).rounded()
        return VolumeConfig.clamped(VolumeConfig.minimum + steps * VolumeConfig.step)
    }
}
