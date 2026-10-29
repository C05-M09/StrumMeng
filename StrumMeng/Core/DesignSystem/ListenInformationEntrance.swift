import SwiftUI

/// A short, staggered entrance. Reduced Motion keeps a brief fade without moving the artwork.
struct ListenInformationEntrance: ViewModifier {
    let visible: Bool
    let reduceMotion: Bool
    let duration: Double
    let delay: Double
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(x: visible || reduceMotion ? 0 : x,
                    y: visible || reduceMotion ? 0 : y)
            .animation(.easeOut(duration: reduceMotion ? 0.15 : duration)
                .delay(reduceMotion ? 0 : delay), value: visible)
    }
}
