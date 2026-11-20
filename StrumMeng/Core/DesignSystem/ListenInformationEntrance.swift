import SwiftUI

/// Matches the four-stage arcade entrance used by BPMRecommendationOverlay.
struct ListenInformationEntrance: ViewModifier {
    enum Stage {
        case banner, mascot, bubble, buttons

        var animation: Animation {
            switch self {
            case .banner: .spring(response: 0.42, dampingFraction: 0.72)
            case .mascot: .spring(response: 0.45, dampingFraction: 0.75).delay(0.12)
            case .bubble: .spring(response: 0.38, dampingFraction: 0.65).delay(0.24)
            case .buttons: .spring(response: 0.35, dampingFraction: 0.75).delay(0.36)
            }
        }
    }

    let visible: Bool
    let reduceMotion: Bool
    let stage: Stage
    let canvasWidth: CGFloat

    private var initialOffset: CGSize {
        switch stage {
        case .banner: CGSize(width: canvasWidth + 400, height: 0)
        case .mascot: CGSize(width: -canvasWidth / 2, height: 0)
        case .bubble: .zero
        case .buttons: CGSize(width: 0, height: 25)
        }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(visible || reduceMotion || stage != .bubble ? 1 : 0.1)
            .opacity(visible || (stage == .banner && !reduceMotion) ? 1 : 0)
            .offset(visible || reduceMotion ? .zero : initialOffset)
            .animation(reduceMotion ? .easeOut(duration: 0.15) : stage.animation, value: visible)
    }
}
