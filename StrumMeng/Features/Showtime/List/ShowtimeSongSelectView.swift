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
        /// The previous and next characters, beside the middle one (smaller than before).
        static let sideSize: CGFloat = 1100
        static let sideFeet: CGFloat = 820
        /// Distance between the middle character and each neighbour.
        static let sideSpacing: CGFloat = 310
        /// Darkening for side characters (negative brightness and reduced exposure) instead of reducing opacity.
        static let sideBrightness: Double = -0.38
        static let sideExposure: Color = Color(white: 0.62)
        /// The middle character while the detail card is open.
        static let detailSize: CGFloat = 1450
        static let detailFeet: CGFloat = 650
        static let detailX: CGFloat = 1079
 
        /// The part of a character's frame that is left out of its tap area on every side, as a
        /// fraction of the frame. The frames are big, so without this the middle character
        /// would cover its neighbours and swallow their taps.
        static let tapInset: CGFloat = 0.3
 
        /// The records card and the Play button under it.
        static let recordsCardCenter = CGPoint(x: 1110, y: 710)
        static let playButtonCenter = CGPoint(x: 1260, y: 925)
    }
    
    /// Drawing order, back to front. The vinyl changes layer: on the stage it is in front of the
        /// characters (a neighbour peeks out from behind it); with the card open it is behind the
        /// character, so the character stands in front of it.
        private enum Layer {
            static let background: Double = 0
            static let swipeArea: Double = 0.5
            /// Side characters stay behind vinyl and center character in both stage and detail view.
            static let sideCharacter: Double = 1
            static let vinylBehind: Double = 2
            static let centerCharacter: Double = 5
            /// Behind floor and title box so floor covers bottom of vinyl and feet
            static let vinylInFront: Double = 5.2
            /// In front of the characters and vinyl, so the floor hides their feet and bottom of vinyl.
            static let floor: Double = 6
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
                    .frame(width: 1100, height: 1100)
                    .position(x: isDetailShown ? 716 : 55, y: isDetailShown ? 498 : 516)
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

                if !isDetailShown {
                    OutlinedText(
                        text: "SHOWTIME",
                        font: AppTypography.bungee(size: 64),
                        foregroundColor: AppColors.white,
                        outlineColor: AppColors.brownInk,
                        outlineWidth: 6,
                        shadowColor: AppColors.yellowAccent,
                        shadowOffset: CGSize(width: 0, height: 8)
                    )
                    .position(x: reference.width / 2, y: 104)
                    .transition(.opacity)
                    .zIndex(Layer.foreground)
                    .allowsHitTesting(false)
                }

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
            Task {
                await viewModel.reloadRecords()
            }
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
            let isVisible = isCenter || (isNeighbor && !isDetailShown)
            let brightness: Double = isCenter ? 0 : Stage.sideBrightness
            let exposure: Color = isCenter ? .white : Stage.sideExposure
            let opacity: Double = isVisible ? 1.0 : 0.0
     
            return Image(ShowtimeAssets.character(forSongID: song.id))
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .brightness(brightness)
                .colorMultiply(exposure)
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

    /// Every title is 2 lines, with a brownPrimary outline and tight line spacing.
    private enum Title {
        static let fontSize: CGFloat = 36
        static let outlineWidth: CGFloat = 4
        static let width: CGFloat = 520
        static let blockHeight: CGFloat = 110
    }

    private func titleLines(for song: Song) -> [String] {
        switch song.id {
        case "twinkle-twinkle":
            return ["TWINKLE TWINKLE", "LITTLE STAR"]
        case "jingle-bells":
            return ["JINGLE BELLS"]
        case "abc-song":
            return ["ABC SONG"]
        case "row-row-row-your-boat":
            return ["ROW, ROW, ROW", "YOUR BOAT"]
        case "down-by-the-riverside":
            return ["DOWN BY", "THE RIVERSIDE"]
        default:
            return TitleLineWrapping.lines(for: song.title.uppercased())
        }
    }
 
    private func titlePlaque(_ song: Song) -> some View {
        let width: CGFloat = isDetailShown ? 787 : 644
        let lines = titleLines(for: song)
        return ZStack(alignment: .trailing) {
            Image(ShowtimeAssets.titleBox)
                .resizable()
                .frame(width: width, height: 180)
            
            VStack(alignment: .trailing, spacing: lines.count == 1 ? 6 : 2) {
                VStack(alignment: .trailing, spacing: -6) {
                    ForEach(lines, id: \.self) { line in
                        OutlinedText(
                            text: line,
                            font: ShowtimeStyle.title(Title.fontSize),
                            foregroundColor: ShowtimeStyle.cream,
                            outlineColor: AppColors.brownPrimary,
                            outlineWidth: Title.outlineWidth,
                            shadowColor: .clear,
                            shadowOffset: .zero,
                            alignment: .trailing
                        )
                    }
                }
                .frame(width: Title.width, alignment: .trailing)
 
                Text("\(song.bpm) BPM")
                    .font(ShowtimeStyle.body(28))
                    .foregroundStyle(ShowtimeStyle.darkBrown)
                    .padding(.top, lines.count == 1 ? 2 : 4)
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
            Color.clear
        }
        .buttonStyle(
            AssetButtonStyle(
                normalAssetName: "Button_Play_Normal",
                pressedAssetName: "Button_Play_Pressed",
                size: CGSize(width: 130, height: 140)
            )
        )
        .position(Stage.playButtonCenter)
        .accessibilityLabel("Play")
    }
}

// MARK: - Previews (5 songs, plus the detail card)

#if DEBUG
@MainActor
private func previewScreen(songIndex: Int, detail: Bool = false) -> some View {
    let player = AVShowtimeSongPlayer()
    let viewModel = SongListViewModel(
        player: player,
        onSongSelected: { _ in },
        onBackRequested: {}
    )
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
