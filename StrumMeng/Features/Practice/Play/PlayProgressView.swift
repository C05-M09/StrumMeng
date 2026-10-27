import SwiftUI

/// Tan capsule with a brown outline; the elapsed part fills in light cream from the left
/// (a small cream dot at 00:00, almost full at 00:59).
struct PlayProgressView: View {
    let progress: Double
    let strokeWidth: CGFloat

    var body: some View {
        GeometryReader { geo in
            let inset = strokeWidth + 1
            let knob = geo.size.height - inset * 2
            ZStack(alignment: .leading) {
                Capsule().fill(AppColor.progressTrack)
                Capsule()
                    .fill(AppColor.progressFill)
                    .frame(width: max(knob, (geo.size.width - inset * 2) * progress), height: knob)
                    .padding(.leading, inset)
                Capsule().strokeBorder(AppColor.progressStroke, lineWidth: strokeWidth)
            }
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.l) {
        PlayProgressView(progress: 0, strokeWidth: 3).frame(height: 30)
        PlayProgressView(progress: 0.5, strokeWidth: 3).frame(height: 30)
        PlayProgressView(progress: 0.98, strokeWidth: 3).frame(height: 30)
    }
    .padding(AppSpacing.xl)
    .background(AppColor.paper)
}
