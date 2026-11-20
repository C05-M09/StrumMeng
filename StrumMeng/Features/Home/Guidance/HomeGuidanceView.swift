import SwiftUI

/// One tap surface consumes touches so a tour tap cannot also activate a Home button.
struct HomeGuidanceView: View {
    let state: HomeGuidanceState
    let onAdvance: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColors.brownInk.opacity(HomeGuidanceLayout.scrimOpacity)
            if state.isShowing {
                bubble
                    .id(state)
                    .transition(.opacity.combined(with: .scale(
                        scale: reduceMotion ? 1 : 0.94,
                        anchor: .trailing)))
            }
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
        .contentShape(Rectangle())
        .onTapGesture(perform: onAdvance)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityHint("Double tap to continue")
        .accessibilityAddTraits([.isButton, .isModal])
        .accessibilityAction { onAdvance() }
        .animation(reduceMotion ? .easeOut(duration: 0.15)
                   : .spring(response: 0.3, dampingFraction: 0.82), value: state)
    }

    private var message: String {
        switch state {
        case .option: "You can manage your paired device and sound settings right here!"
        case .guidebook: "Curious about tempo? Find simple guides to the basics here! You can always come back anytime."
        default: ""
        }
    }

    private var bubble: some View {
        let isOption = state == .option
        let width = isOption ? HomeGuidanceLayout.optionWidth : HomeGuidanceLayout.guidebookWidth
        return VStack(spacing: HomeGuidanceLayout.copySpacing) {
            Text(message).font(AppTypography.dmMono(size: HomeGuidanceLayout.textSize))
                .foregroundStyle(AppColors.brownInk)
            Text("Tap anywhere to continue")
                .font(AppTypography.dmMono(size: HomeGuidanceLayout.hintSize))
                .foregroundStyle(AppColors.yellowAccent)
        }
        .multilineTextAlignment(.center)
        .frame(width: width - HomeGuidanceLayout.pointerLength - 2 * HomeGuidanceLayout.padding)
        .fixedSize(horizontal: false, vertical: true)
        .padding(HomeGuidanceLayout.padding)
        .padding(.trailing, HomeGuidanceLayout.pointerLength)
        .background {
            HomeGuidanceBubble()
                .fill(AppColors.white)
                .shadow(color: AppColors.brownInk, radius: 0,
                        x: HomeGuidanceLayout.shadowX, y: HomeGuidanceLayout.shadowY)
        }
        .position(isOption ? HomeGuidanceLayout.optionCenter : HomeGuidanceLayout.guidebookCenter)
    }

}

#Preview("Option guidance", traits: .landscapeLeft) {
    Image("Cover").resizable().overlay {
        HomeGuidanceView(state: .option, onAdvance: {})
    }
    .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
}

#Preview("Guidebook guidance", traits: .landscapeLeft) {
    Image("Cover").resizable().overlay {
        HomeGuidanceView(state: .guidebook, onAdvance: {})
    }
    .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
}
