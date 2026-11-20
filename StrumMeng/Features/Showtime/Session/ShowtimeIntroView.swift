import SwiftUI

struct ShowtimeIntroView: View {
    let onNext: () -> Void
    @State private var visible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.playSoundEffect) private var playSoundEffect

    init(onNext: @escaping () -> Void, visibleInitially: Bool = false) {
        self.onNext = onNext
        _visible = State(initialValue: visibleInitially)
    }
    var body: some View {
        ZStack {
            AppColors.brownInk.opacity(ShowtimeLayout.informationScrimOpacity)
            Image("Showtime_Assets/Showtime_Box").resizable()
                .frame(width: ShowtimeLayout.informationBannerSize.width, height: ShowtimeLayout.informationBannerSize.height)
                .position(ShowtimeLayout.informationBannerCenter)
                .modifier(entrance(.banner))
            Image("Retry_Character").resizable().scaledToFit()
                .frame(width: ShowtimeLayout.informationCharacterSize.width)
                .position(ShowtimeLayout.informationCharacterCenter)
                .modifier(entrance(.mascot))
            ZStack {
                Image("Showtime_Assets/Listen_Bubble").resizable().scaledToFit()
                    .frame(width: ShowtimeLayout.informationBubbleSize.width,
                           height: ShowtimeLayout.informationBubbleSize.height)
                Text("Let's play a song! Strum along to the beat while the chords change automatically with the music.")
                    .font(AppTypography.dmMono(size: 28))
                    .foregroundStyle(AppColors.brownInk).multilineTextAlignment(.center)
                    .frame(width: 700)
                    .offset(x: ShowtimeLayout.informationTextCenter.x - ShowtimeLayout.informationBubbleCenter.x,
                            y: ShowtimeLayout.informationTextCenter.y - ShowtimeLayout.informationBubbleCenter.y)
            }
            .frame(width: ShowtimeLayout.informationBubbleSize.width,
                   height: ShowtimeLayout.informationBubbleSize.height)
            .modifier(entrance(.bubble))
            .position(ShowtimeLayout.informationBubbleCenter)
            Button("Next", action: onNext)
                .buttonStyle(AssetButtonStyle(normalAssetName: "Button_Next_Normal",
                    pressedAssetName: "Button_Next_Pressed", size: CGSize(width: 252, height: 112)))
                .position(ShowtimeLayout.informationNextCenter).modifier(entrance(.buttons))
        }
        .accessibilityAddTraits(.isModal)
        // Pops in like Practice's Listen information.
        .onAppear {
            playSoundEffect(.popUp)
            visible = true
        }
    }
    private func entrance(_ stage: ListenInformationEntrance.Stage) -> ListenInformationEntrance {
        ListenInformationEntrance(visible: visible, reduceMotion: reduceMotion, stage: stage,
                                  canvasWidth: ShowtimeLayout.size.width)
    }
}
