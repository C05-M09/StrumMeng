import SwiftUI

struct PairingIntroductionView: View {
    let onContinue: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    var body: some View {
        GeometryReader { proxy in
            let size = AppLayout.referenceSize
            let scale = max(proxy.size.width / size.width, proxy.size.height / size.height)
            ZStack {
                AppColors.brownInk.opacity(PairingIntroductionLayout.scrimOpacity)
                Image("Listen_Box").resizable()
                    .frame(width: PairingIntroductionLayout.bannerSize.width,
                           height: PairingIntroductionLayout.bannerSize.height)
                    .position(PairingIntroductionLayout.bannerCenter)
                    .modifier(entrance(.banner))
                    .allowsHitTesting(false)
                Image("Retry_Character").resizable().scaledToFit()
                    .frame(width: PairingIntroductionLayout.characterSize.width,
                           height: PairingIntroductionLayout.characterSize.height)
                    .position(PairingIntroductionLayout.characterCenter)
                    .modifier(entrance(.mascot))
                    .accessibilityHidden(true)
                ZStack {
                    Image("Listen_Bubble").resizable().scaledToFit()
                        .accessibilityHidden(true)
                    VStack(spacing: PairingIntroductionLayout.copySpacing) {
                        Text("Hey there, I'm Meng!")
                            .font(AppTypography.bungee(size: PairingIntroductionLayout.copyFontSize))
                            .foregroundStyle(AppColors.brownInk)
                        Text("Let's pair your iPhone with this iPad\nbefore we start strumming!")
                            .font(AppTypography.dmMono(size: PairingIntroductionLayout.copyFontSize))
                            .foregroundStyle(AppColors.brownInk)
                        Text("Tap Next when you’re ready.")
                            .font(AppTypography.dmMono(size: PairingIntroductionLayout.hintFontSize))
                            .foregroundStyle(AppColors.yellowAccent)
                    }
                    .multilineTextAlignment(.center)
                    .frame(width: PairingIntroductionLayout.textWidth)
                    .offset(PairingIntroductionLayout.textOffset)
                }
                .frame(width: PairingIntroductionLayout.bubbleSize.width,
                       height: PairingIntroductionLayout.bubbleSize.height)
                .modifier(entrance(.bubble))
                .position(PairingIntroductionLayout.bubbleCenter)
                Button("Pair my iPhone", action: onContinue)
                    .buttonStyle(AssetButtonStyle(
                        normalAssetName: "Button_Next_Normal", pressedAssetName: "Button_Next_Pressed",
                        size: PairingIntroductionLayout.nextSize))
                    .position(PairingIntroductionLayout.nextCenter)
                    .modifier(entrance(.buttons))
            }
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .onAppear { visible = true }
    }

    private func entrance(_ stage: ListenInformationEntrance.Stage) -> ListenInformationEntrance {
        ListenInformationEntrance(visible: visible, reduceMotion: reduceMotion,
                                  stage: stage, canvasWidth: AppLayout.referenceSize.width)
    }
}

#Preview("Meng invites the player to pair", traits: .landscapeLeft) {
    ZStack {
        Image("Play_BG").resizable().ignoresSafeArea()
        PairingIntroductionView(onContinue: {})
    }
}
