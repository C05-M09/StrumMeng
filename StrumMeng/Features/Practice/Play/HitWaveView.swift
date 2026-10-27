import SwiftUI

/// The colour wave that spreads from the hit ring after a Perfect or Too Early.
struct HitWaveView: View {
    let judgement: PlayJudgement?
    let songTime: TimeInterval
    let ringSize: CGFloat

    var body: some View {
        ZStack {
            if let judgement, let wave = HitAnimation.wave(judgement: judgement, songTime: songTime) {
                Circle()
                    .stroke(HitRingView.color(for: judgement.feedback), lineWidth: ringSize * 0.04)
                    .scaleEffect(wave.scale)
                    .opacity(wave.opacity)
            }
        }
        .frame(width: ringSize, height: ringSize)
        .allowsHitTesting(false)
    }
}
