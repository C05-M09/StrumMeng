import SwiftUI

/// The six slots of a pair code. Digits not typed yet leave their slot empty.
/// The iPad uses the defaults (paper slots); the iPhone keypad passes its own fill, border and gap.
struct PairCodeSlotsView: View {
    let code: String
    let slotSize: CGSize
    var fill: Color = AppColor.paper
    /// Drawn inside the slot. Defaults to a width in proportion to the slot.
    var borderWidth: CGFloat?
    /// Defaults to a gap in proportion to the slot.
    var spacing: CGFloat?

    var body: some View {
        let digits = Array(code)
        HStack(spacing: spacing ?? slotSize.width * 0.14) {
            ForEach(0..<PairCode.length, id: \.self) { index in
                let shape = RoundedRectangle(cornerRadius: slotSize.width * 0.18)
                Text(index < digits.count ? String(digits[index]) : "")
                    .font(AppTypography.dmMono(size: slotSize.height * 0.56))
                    .foregroundStyle(AppColor.ink)
                    .frame(width: slotSize.width, height: slotSize.height)
                    .background(shape.fill(fill))
                    .overlay(shape.strokeBorder(AppColor.track, lineWidth: borderWidth ?? slotSize.width * 0.04))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pair code \(code)")
    }
}

#Preview("Full and partial") {
    VStack(spacing: AppSpacing.l) {
        PairCodeSlotsView(code: "482913", slotSize: CGSize(width: 44, height: 56))
        PairCodeSlotsView(code: "48", slotSize: CGSize(width: 44, height: 56))
    }
    .padding(AppSpacing.xl)
    .background(AppColor.laneBackground)
}

#Preview("iPhone keypad style") {
    PairCodeSlotsView(code: "48", slotSize: CGSize(width: 46.8, height: 62.2),
                      fill: AppColors.white, borderWidth: 3, spacing: 3.9)
        .padding(AppSpacing.xl)
        .background(AppColors.orange)
}
