import SwiftUI

/// The hollow ring nodes pass through. Cream at rest; shows the latest result's colour for a moment.
struct HitRingView: View {
    let size: CGFloat
    let judgement: PlayJudgement?
    /// 1 while the result colour shows (HitAnimation.ringStrength), 0 otherwise.
    let strength: Double
    /// Thicker stroke for a moment after every swipe (1 = normal).
    var lineScale: Double = 1

    var body: some View {
        let lineWidth = size * 0.07 * lineScale
        ZStack {
            Circle().strokeBorder(AppColor.paper, lineWidth: lineWidth)
            if let judgement {
                Circle()
                    .strokeBorder(Self.color(for: judgement.feedback), lineWidth: lineWidth * 1.15)
                    .opacity(strength)
            }
        }
        .frame(width: size, height: size)
    }

    static func color(for feedback: PlayFeedback) -> Color {
        switch feedback {
        case .perfect: AppColor.perfect
        case .tooEarly: AppColor.tooEarly
        case .miss: AppColor.miss
        }
    }
}

#Preview("Idle, perfect, too early, miss") {
    HStack(spacing: AppSpacing.l) {
        HitRingView(size: 90, judgement: nil, strength: 0)
        HitRingView(size: 90, judgement: PlayJudgement(feedback: .perfect, time: 0), strength: 1)
        HitRingView(size: 90, judgement: PlayJudgement(feedback: .tooEarly, time: 0), strength: 1)
        HitRingView(size: 90, judgement: PlayJudgement(feedback: .miss, time: 0), strength: 1)
    }
    .padding(AppSpacing.xl)
    .background(AppColor.ink)
}
