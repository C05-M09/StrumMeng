import SwiftUI

/// Pause modal (hi-fi "Practice-Play Copy 10"): cream card with a dark outline and a red lip,
/// asking whether to end the session, with Resume / Restart / Back to Menu.
struct PauseMenuOverlay: View {
    let unit: CGFloat
    let onResume: () -> Void
    let onRestart: () -> Void
    let onBackToMenu: () -> Void

    var body: some View {
        let radius = 22 * unit
        let outline = 4 * unit
        let card = RoundedRectangle(cornerRadius: radius)

        VStack(spacing: 14 * unit) {
            Text("ARE YOU SURE WANT\nTO END THE SESSION?")
                .font(AppFont.display(30 * unit))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.ink)
                .padding(.bottom, 10 * unit)
            button("Resume", .primary, action: onResume)
            button("Restart", .primary, action: onRestart)
            button("Back to Menu", .secondary, action: onBackToMenu)
        }
        .padding(.horizontal, 64 * unit)
        .padding(.top, 44 * unit)
        .padding(.bottom, 50 * unit)
        .background {
            ZStack {
                // red lip under the card
                card.fill(AppColor.boardRed).offset(y: 10 * unit)
                card.strokeBorder(AppColor.ink, lineWidth: outline).offset(y: 10 * unit)
                card.fill(AppColor.paper)
                card.strokeBorder(AppColor.ink, lineWidth: outline)
            }
        }
    }

    private func button(_ title: String, _ style: ChunkyButton.Style, action: @escaping () -> Void) -> some View {
        ChunkyButton(title: title, style: style, fontSize: 24 * unit, width: 300 * unit, height: 50 * unit,
                     action: action)
    }
}

#Preview {
    PauseMenuOverlay(unit: 1, onResume: {}, onRestart: {}, onBackToMenu: {})
        .padding(60)
        .background(AppColor.dim.opacity(0.6))
}
