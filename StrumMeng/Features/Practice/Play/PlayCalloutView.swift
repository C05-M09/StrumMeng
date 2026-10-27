import SwiftUI

/// Big white Bungee text over the veil, centred on the rail: "READY?" and the 3, 2, 1 count-in.
struct PlayCalloutView: View {
    let text: String
    let fontSize: CGFloat
    /// 0...1 into the current beat; each new text lands big and settles. 1 = at rest.
    var beatProgress: Double = 1

    var body: some View {
        let settle = min(1, beatProgress * 4)
        let eased = 1 - pow(1 - settle, 3)
        Text(text)
            .font(AppFont.display(fontSize))
            .foregroundStyle(AppColor.calloutText)
            .shadow(color: AppColor.ink.opacity(0.6), radius: 0, x: 0, y: fontSize * 0.06)
            .scaleEffect(1.4 - 0.4 * eased)
            .opacity(0.35 + 0.65 * eased)
            .fixedSize()
    }
}

#Preview {
    VStack(spacing: AppSpacing.xl) {
        PlayCalloutView(text: "READY?", fontSize: 52)
        PlayCalloutView(text: "2", fontSize: 140, beatProgress: 0.6)
    }
    .padding(AppSpacing.xl)
    .background(AppColor.dim)
}
