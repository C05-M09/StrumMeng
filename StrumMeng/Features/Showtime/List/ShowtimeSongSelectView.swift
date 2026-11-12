import SwiftUI

/// Song picker: the character of the song is on stage with the previous and next characters faded
/// beside it. Swipe (or tap a faded one) to change song, tap the middle character to open the
/// detail card. Back closes the card first, then leaves the screen.
struct ShowtimeSongSelectView: View {
    let viewModel: SongListViewModel

    @Environment(\.scenePhase) private var scenePhase
    @State private var isDetailShown: Bool

    init(viewModel: SongListViewModel, initiallyShowsDetail: Bool = false) {
        self.viewModel = viewModel
        _isDetailShown = State(initialValue: initiallyShowsDetail)
    }

    private let reference = AppLayout.referenceSize

    
    /// Sizes and places of the characters, in reference points. Tune them here.
    ///
    /// A character's picture has a lot of empty space around the cat, so its frame is much bigger
    /// than the cat you see. Places are given as where the cat's FEET stand (`...Feet`).
    /// `feetFraction` says how far down the frame the feet are, and the code works out the frame
    /// from that, so a bigger character grows upwards from the same spot on the floor.
    private enum Stage {
        /// 0.68 = the feet are at 68% of the frame's height (measured on the Row Your Boat cat).
        /// If a cat floats above the floor or sinks below it, nudge this number.
        static let feetFraction: CGFloat = 0.68
 
        /// The character in the middle. The floor is in front of it, so its feet go a little
        /// below the floor's edge (y 842) and are hidden behind it. Lower number = more visible.
        static let centerSize: CGFloat = 1800
        static let centerFeet: CGFloat = 900
        static let centerX: CGFloat = 941
        /// The previous and next characters, beside the middle one (about 70% of its size).
        static let sideSize: CGFloat = 1400
        static let sideFeet: CGFloat = 805
        /// Distance between the middle character and each neighbour. Smaller = closer together.
        static let sideSpacing: CGFloat = 360
        static let sideOpacity: Double = 0.35
        /// The middle character while the detail card is open.
        static let detailSize: CGFloat = 1450
        static let detailFeet: CGFloat = 650
        static let detailX: CGFloat = 1079
 
        /// The part of a character's frame that is left out of its tap area on every side, as a
        /// fraction of the frame. The frames are big, so without this the middle character
        /// would cover its neighbours and swallow their taps.
        static let tapInset: CGFloat = 0.3
 
        /// The records card (with its stars) and the Play button under it. Move both together.
        static let recordsCardCenter = CGPoint(x: 1110, y: 672)
        static let playButtonY: CGFloat = 992
    }
    
    /// Drawing order, back to front. The vinyl changes layer: on the stage it is in front of the
        /// characters (a neighbour peeks out from behind it); with the card open it is behind the
        /// character, so the character stands in front of it.
        private enum Layer {
            static let background: Double = 0
            static let vinylBehind: Double = 2
            static let swipeArea: Double = 3
            static let sideCharacter: Double = 4
            static let centerCharacter: Double = 5
            /// In front of the characters, so the floor hides their feet.
            static let floor: Double = 5.5
            static let vinylInFront: Double = 6
            static let wall: Double = 7
            /// Plaque, hint, card panels, Play and Back. Ties keep the order they are written in.
            static let foreground: Double = 10
        }

    var body: some View {
        ShowtimeCanvas {
            ZStack(alignment: .topLeading) {
                Image(ShowtimeAssets.background)
                    .resizable()
                    .scaledToFill()
                    .frame(width: reference.width, height: reference.height)
                    .clipped()
                    .zIndex(Layer.background)
                    .allowsHitTesting(false)

                Image(ShowtimeAssets.floor)
                    .resizable()
                    .frame(width: reference.width, height: 190)
                    .position(x: reference.width / 2, y: 937)
                    .zIndex(Layer.floor)
                    .allowsHitTesting(false)

                Image(ShowtimeAssets.vinyl)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 757, height: 757)
                    .position(x: isDetailShown ? 716 : 55, y: isDetailShown ? 498 : 421)
                    .zIndex(isDetailShown ? Layer.vinylBehind : Layer.vinylInFront)
                    .allowsHitTesting(false)

                Image(ShowtimeAssets.woodWall)
                    .resizable()
                    .frame(width: wallWidth, height: 860)
                    .position(x: wallWidth / 2, y: 430)
                    .zIndex(Layer.wall)
                    .allowsHitTesting(false)

                // Empty area of the stage still swipes.
                Color.clear
                    .frame(width: reference.width, height: 860)
                    .contentShape(Rectangle())
                    .gesture(swipe)
                    .position(x: reference.width / 2, y: 430)
                    .zIndex(Layer.swipeArea)

                carousel

                if let song = viewModel.state.selectedSong {
                    // The plaque is in front of the characters, like in the design.
                    titlePlaque(song)
                        .zIndex(Layer.foreground)

                    if !isDetailShown {
                        Text("Swipe character to choose a song")
                            .font(ShowtimeStyle.body(34))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 520)
                            .position(x: 941, y: 916)
                            .transition(.opacity)
                            .zIndex(Layer.foreground)
                    }

                    if isDetailShown {
                        ShowtimeSongDetailCard(song: song)
                            .position(x: 358, y: 410)
                            .transition(.opacity)
                            .zIndex(Layer.foreground)
                        ShowtimeRecordsCard(stars: viewModel.bestStars(for: song) ?? 0) {
                            recordsContent(for: song)
                        }
                        .position(Stage.recordsCardCenter)
                        .transition(.opacity)
                        .zIndex(Layer.foreground)
                        playButton
                            .zIndex(Layer.foreground)
                    }
                }

                BackButton { handleBack() }
                    .frame(width: 83, height: 83)
                    .position(x: 110, y: 107)
                    .zIndex(Layer.foreground)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isDetailShown)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.state.selectedIndex)
        .onAppear {
            viewModel.startPlayback()
        }
        .onDisappear {
            viewModel.stopPlayback()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.resumePlayback()
            } else {
                viewModel.pausePlayback()
            }
        }
    }

    private var wallWidth: CGFloat { isDetailShown ? 716 : 215 }

    private func handleBack() {
        if isDetailShown {
            isDetailShown = false
        } else {
            viewModel.send(.tapBack)
        }
    }

    // MARK: - Characters

    /// Every song has its own character view that slides to its place as the selection moves, so a
    /// swipe animates smoothly and wraps around from the last song to the first.
    @ViewBuilder
    private var carousel: some View {
        let songs = viewModel.state.songs
        if let selectedIndex = viewModel.state.selectedIndex {
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                character(
                    song,
                    offset: circularOffset(of: index, from: selectedIndex, count: songs.count)
                )
            }
        }
    }

    /// How many places a song is from the selected one, going the short way round:
    /// -1 is the one on the left, 1 the one on the right.
    private func circularOffset(of index: Int, from selected: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var distance = (index - selected) % count
        if distance > count / 2 {
            distance -= count
        } else if distance < -(count / 2) {
            distance += count
        }
        return distance
    }

    private func character(_ song: Song, offset: Int) -> some View {
            let isCenter = offset == 0
            let isNeighbor = abs(offset) == 1
            let isTappable = isCenter || (isNeighbor && !isDetailShown)
     
            let size: CGFloat = isCenter
                ? (isDetailShown ? Stage.detailSize : Stage.centerSize)
                : Stage.sideSize
            let feet: CGFloat = isCenter
                ? (isDetailShown ? Stage.detailFeet : Stage.centerFeet)
                : Stage.sideFeet
            let position = CGPoint(
                x: isCenter
                    ? (isDetailShown ? Stage.detailX : Stage.centerX)
                    : Stage.centerX + CGFloat(offset) * Stage.sideSpacing,
                // The middle of the frame, worked out from where the feet should stand.
                y: feet - size * (Stage.feetFraction - 0.5)
            )
            let opacity: Double = isCenter
                ? 1
                : (isNeighbor && !isDetailShown ? Stage.sideOpacity : 0)
     
            return Image(ShowtimeAssets.character(forSongID: song.id))
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(opacity)
                .contentShape(Rectangle().inset(by: size * Stage.tapInset))
                .allowsHitTesting(isTappable)
                .gesture(swipe)
                .onTapGesture { handleTap(offset: offset) }
                .position(position)
                .zIndex(isCenter ? Layer.centerCharacter : Layer.sideCharacter)
                .accessibilityHidden(!isCenter)
        }

    private func handleTap(offset: Int) {
        guard !isDetailShown || offset == 0 else { return }
        switch offset {
        case 0:
            if !isDetailShown { isDetailShown = true }
        case 1:
            viewModel.send(.swipeLeft)
        case -1:
            viewModel.send(.swipeRight)
        default:
            break
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { value in
            guard !isDetailShown else { return }
            if value.translation.width < -60 {
                viewModel.send(.swipeLeft)
            } else if value.translation.width > 60 {
                viewModel.send(.swipeRight)
            }
        }
    }

    // MARK: - Plaque, records, play

    /// The song's own records view. It loads again every time the card opens.
    @ViewBuilder
    private func recordsContent(for song: Song) -> some View {
        if let recordsViewModel = viewModel.recordsViewModels[song.id] {
            ShowtimeRecordsView(viewModel: recordsViewModel)
        } else {
            ShowtimeRecordsContentView(state: viewModel.recordsFallbackState)
        }
    }

    /// Every title is the same size, with a brownPrimary outline. A long title goes onto a second
    /// line. A short one sits on the lower line, right above the BPM, so the BPM never moves.
    private enum Title {
        static let fontSize: CGFloat = 30
        static let outlineWidth: CGFloat = 4
        /// Wide enough for "TWINKLE TWINKLE" on one line; the rest of that title goes below it.
        static let width: CGFloat = 400
        /// Room for two lines.
        static let blockHeight: CGFloat = 110
    }
 
    private func titlePlaque(_ song: Song) -> some View {
        let width: CGFloat = isDetailShown ? 787 : 644
        return ZStack(alignment: .trailing) {
            Image(ShowtimeAssets.titleBox)
                .resizable()
                .frame(width: width, height: 180)
            
            VStack(alignment: .trailing, spacing: 2) {
                OutlinedText(
                    text: song.title.uppercased(),
                    font: ShowtimeStyle.title(Title.fontSize),
                    foregroundColor: ShowtimeStyle.cream,
                    outlineColor: AppColors.brownPrimary,
                    outlineWidth: Title.outlineWidth,
                    shadowColor: .clear,
                    shadowOffset: .zero,
                    alignment: .trailing
                )
                .lineLimit(2)
                .frame(width: Title.width, height: Title.blockHeight, alignment: .bottomTrailing)
 
                Text("\(song.bpm) BPM")
                    .font(ShowtimeStyle.body(30))
                    .foregroundStyle(ShowtimeStyle.darkBrown)
            }
            .id(song.id)
            .transition(.opacity)
            .padding(.trailing, 50)
        }
        .frame(width: width, height: 180)
        .position(x: width / 2, y: 884)
    }
 

    private var playButton: some View {
        Button {
            viewModel.send(.selectSong)
        } label: {
            Text("PLAY")
                .font(ShowtimeStyle.body(40))
                .foregroundStyle(ShowtimeStyle.cream)
                .frame(width: 260, height: 64)
                .background(Capsule().fill(ShowtimeStyle.downRed))
                .overlay(Capsule().stroke(ShowtimeStyle.darkBrown, lineWidth: 5))
        }
        .buttonStyle(.plain)
        .position(x: Stage.recordsCardCenter.x, y: Stage.playButtonY)
    }
}

// MARK: - Previews (5 songs, plus the detail card)

#if DEBUG
@MainActor
private func previewScreen(songIndex: Int, detail: Bool = false) -> some View {
    let viewModel = SongListViewModel(onSongSelected: { _ in }, onBackRequested: {})
    for _ in 0..<songIndex { viewModel.send(.swipeLeft) }
    return ShowtimeSongSelectView(viewModel: viewModel, initiallyShowsDetail: detail)
}

#Preview("1 Twinkle Twinkle", traits: .fixedLayout(width: 1376, height: 1032)) { previewScreen(songIndex: 0) }
#Preview("2 ABC Song", traits: .fixedLayout(width: 1376, height: 1032)) { previewScreen(songIndex: 1) }
#Preview("3 Row Row", traits: .fixedLayout(width: 1376, height: 1032)) { previewScreen(songIndex: 2) }
#Preview("4 Jingle Bells", traits: .fixedLayout(width: 1376, height: 1032)) { previewScreen(songIndex: 3) }
#Preview("5 Riverside", traits: .fixedLayout(width: 1376, height: 1032)) { previewScreen(songIndex: 4) }
#Preview("Detail, no record", traits: .fixedLayout(width: 1376, height: 1032)) { previewScreen(songIndex: 3, detail: true) }
#endif
