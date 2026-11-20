import SwiftUI

/// Rounded rectangle button with a dark outline and Bungee label (pause modal, Ready, Replay, Retry).
struct ChunkyButton: View {
    enum Style {
        case primary, secondary, danger

        var fill: Color {
            switch self {
            case .primary: AppColor.buttonPrimary
            case .secondary: AppColor.buttonSecondary
            case .danger: AppColor.buttonDanger
            }
        }
    }

    let title: String
    var style: Style = .primary
    var fontSize: CGFloat = 22
    var width: CGFloat = 260
    var height: CGFloat = 46
    var hasDropShadow = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let shape = RoundedRectangle(cornerRadius: height * 0.24)
            Text(title.uppercased())
                .font(AppFont.display(fontSize))
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: width, height: height)
                .background {
                    ZStack {
                        if hasDropShadow {
                            shape.fill(AppColor.ink).offset(y: height * 0.09)
                        }
                        shape.fill(style.fill)
                        shape.strokeBorder(AppColor.ink, lineWidth: max(2, height * 0.06))
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    VStack(spacing: AppSpacing.m) {
        ChunkyButton(title: "Resume") {}
        ChunkyButton(title: "Restart") {}
        ChunkyButton(title: "Back to Menu", style: .secondary) {}
        ChunkyButton(title: "Retry", style: .danger, hasDropShadow: true) {}
    }
    .padding(AppSpacing.xl)
    .background(AppColor.paper)
}
