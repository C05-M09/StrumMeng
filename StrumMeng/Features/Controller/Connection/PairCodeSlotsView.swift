import SwiftUI

/// The six paper slots of a pair code. Digits not typed yet leave their slot empty.
struct PairCodeSlotsView: View {
    let code: String
    let slotSize: CGSize

    var body: some View {
        let digits = Array(code)
        HStack(spacing: slotSize.width * 0.14) {
            ForEach(0..<PairCode.length, id: \.self) { index in
                let shape = RoundedRectangle(cornerRadius: slotSize.width * 0.18)
                Text(index < digits.count ? String(digits[index]) : "")
                    .font(AppTypography.dmMono(size: slotSize.height * 0.56))
                    .foregroundStyle(AppColor.ink)
                    .frame(width: slotSize.width, height: slotSize.height)
                    .background(shape.fill(AppColor.paper))
                    .overlay(shape.strokeBorder(AppColor.track, lineWidth: slotSize.width * 0.04))
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
