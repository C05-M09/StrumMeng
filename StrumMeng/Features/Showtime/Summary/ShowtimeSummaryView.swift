//
//  ShowtimeSummaryView.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import SwiftUI

struct ShowtimeSummaryView: View {
    let viewModel: ShowtimeSummaryViewModel
    let songInfo: ShowtimeSongInfo
    var onNavigate: ((ShowtimeSummaryDestination) -> Void)?
    var makeReplayView: ((SessionResult, @escaping () -> Void) -> AnyView)?

    @State private var activeReplayResult: SessionResult?
    @State private var isShowingFeedbackOverlay: Bool
    @State private var isGarageOpen: Bool = false
    @Environment(\.playSoundEffect) private var playSoundEffect

    init(
        viewModel: ShowtimeSummaryViewModel,
        songInfo: ShowtimeSongInfo? = nil,
        showIntroOverlay: Bool = true,
        onNavigate: ((ShowtimeSummaryDestination) -> Void)? = nil,
        makeReplayView: ((SessionResult, @escaping () -> Void) -> AnyView)? = nil
    ) {
        self.viewModel = viewModel
        self.songInfo = songInfo ?? .fallback(for: viewModel.result)
        self.onNavigate = onNavigate
        self.makeReplayView = makeReplayView
        self._isShowingFeedbackOverlay = State(initialValue: showIntroOverlay)
    }

    var body: some View {
        GeometryReader { proxy in
            let sx = proxy.size.width / AppLayout.referenceSize.width
            let sy = proxy.size.height / AppLayout.referenceSize.height

            ZStack {
                // 1. Background Penuh
                AppColors.cream
                    .ignoresSafeArea()

                // 2. Konten Teks & Tombol di atas Background (reusing Practice Summary_BG until Showtime asset is ready)
                mainCanvas
                    .frame(
                        width: AppLayout.referenceSize.width,
                        height: AppLayout.referenceSize.height
                    )
                    .scaleEffect(x: sx, y: sy)
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )

                // 3. Layar Replay (Slide)
                if let replayResult = activeReplayResult {
                    replayOverlay(for: replayResult)
                        .transition(.slide)
                        .zIndex(100)
                }

                // 4. Intro Feedback Overlay
                if isShowingFeedbackOverlay {
                    ShowtimeSummaryFeedbackOverlay(result: viewModel.result) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isShowingFeedbackOverlay = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(50)
                }

                // 5. Garage Shutter Opening Upwards on Appear
                Image("Garage")
                    .resizable()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .offset(y: isGarageOpen ? -proxy.size.height : 0)
                    .allowsHitTesting(!isGarageOpen)
                    .zIndex(200)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: activeReplayResult != nil)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            playSoundEffect(.garage)
            withAnimation(.spring(response: 0.58, dampingFraction: 0.86).delay(0.10)) {
                isGarageOpen = true
            }
        }
        .task {
            await viewModel.onAppear()
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .navigating(let destination) = newState {
                if case .replay(let result) = destination {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        activeReplayResult = result
                    }
                }
                onNavigate?(destination)
            }
        }
    }

    // MARK: - Main Canvas (1376 x 1032)
    @ViewBuilder
    private var mainCanvas: some View {
        ZStack {
            // Reusing Practice Summary_BG until dedicated Showtime Summary artwork is ready.
            Image("3_Showtime Summary")
                .resizable()
                .frame(
                    width: AppLayout.referenceSize.width,
                    height: AppLayout.referenceSize.height
                )

            // --- KOLOM KIRI ---
            leftColumnElements

            // --- KOLOM KANAN ---
            rightColumnElements
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
    }

    // MARK: - Right Column Elements
    @ViewBuilder
    private var rightColumnElements: some View {
        // 1. Nama Lagu (di dalam kotak cokelat)
        VStack(alignment: .leading) {
            Spacer()
            Text(songInfo.title.uppercased())
                .font(AppTypography.bungee(size: 40))
                .foregroundStyle(AppColors.white)
                .minimumScaleFactor(0.6)
                .lineLimit(3)
        }
        .frame(width: 320, height: 180, alignment: .bottomLeading)
        .position(x: 1136, y: 420)

        // 2. Baris Durasi & BPM (di bawah kotak cokelat)
        HStack(alignment: .firstTextBaseline) {
            Text(songInfo.durationLabel)
                .font(AppTypography.dmMono(size: 25))
                .foregroundStyle(AppColors.white)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("BPM")
                    .font(AppTypography.dmMono(size: 25))
                    .foregroundStyle(AppColors.white)

                Text("\(viewModel.result.bpm)")
                    .font(AppTypography.dmMono(size: 50))
                    .foregroundStyle(AppColors.white)
            }
        }
        .frame(width: 325)
        .position(x: 1136, y: 580)

        // 3. CHORDS (di bawah baris Durasi & BPM)
        VStack(alignment: .leading, spacing: 0) {
            Text("CHORDS")
                .font(AppTypography.bungee(size: 30))
                .foregroundStyle(AppColors.white)

            HStack(spacing: 36) {
                ForEach(Array(songInfo.chords.enumerated()), id: \.offset) { _, chord in
                    Text(chord)
                        .font(AppTypography.dmMono(size: 50))
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.white)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .frame(width: 325, alignment: .leading)
        .position(x: 1136, y: 695)

        // 4. Tombol REPLAY & RETRY
        VStack(spacing: 8) {
            Button {
                viewModel.send(.tapReplay)
            } label: {
                EmptyView()
            }
            .buttonStyle(
                AssetButtonStyle(
                    normalAssetName: "Button_Replay_Normal",
                    pressedAssetName: "Button_Replay_Pressed",
                    size: CGSize(width: 360, height: 104)
                )
            )

            Button {
                viewModel.send(.tapRetry)
            } label: {
                EmptyView()
            }
            .buttonStyle(
                AssetButtonStyle(
                    normalAssetName: "Button_Retry_Normal",
                    pressedAssetName: "Button_Retry_Pressed",
                    size: CGSize(width: 360, height: 104)
                )
            )
        }
        .frame(width: 760)
        .position(x: 1133, y: 860)
    }

    // MARK: - Left Column Elements (Tanpa Background Tambahan)
    @ViewBuilder
    private var leftColumnElements: some View {
        let result = viewModel.result
        let feedback = ShowtimeSummaryFeedbackContent(result: result)
        let accuracyPercent = Int((result.accuracy * 100).rounded())

        // 1. Tombol "BACK TO MAIN"
        Button {
            viewModel.send(.tapBackToMain)
        } label: {
            Image("Button_Back to Main")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 42)
        }
        .buttonStyle(ScaleOnlyButtonStyle())
        .position(x: 212, y: 120)

        // 2. Bintang (0 - 3) di atas pill ACCURACY
        Image(ShowtimeAssets.star(viewModel.stars))
            .resizable()
            .scaledToFit()
            .frame(width: 266)
            .position(x: 477, y: 330)

        // 3. Banner Background Chatbox (hijau teal di belakang headline, sama seperti overlay)
        Image("Summary_Title chatbox")
            .resizable()
            .scaledToFit()
            .frame(width: 610)
            .position(x: 480, y: 685)

        // 3b. Header Banner ("AWESOME!", "NICE!!", "YOU GOOD?")
        VStack(alignment: .leading) {
            Text(feedback.headline)
                .font(AppTypography.bungee(size: 55))
                .foregroundStyle(AppColors.white)
        }
        .frame(width: 400, height: 100, alignment: .leading)
        .position(x: 595, y: 680)

        // 4. Feedback Chatbox Card (sama seperti ShowtimeSummaryFeedbackOverlay)
        ZStack(alignment: .leading) {
            Image("Summary_Chatbox")
                .resizable()
                .scaledToFit()
                .frame(width: 760)

            Text(feedback.message)
                .font(AppTypography.dmMono(size: 28))
                .fontWeight(.bold)
                .foregroundStyle(AppColors.brownInk)
                .lineSpacing(4)
                .minimumScaleFactor(0.85)
                .frame(width: 480, height: 190, alignment: .leading)
                .padding(.leading, 220)
                .padding(.bottom, 20)
        }
        .position(x: 560, y: 870)

        // 5. Ekspresi Maskot Karakter (di depan chatbox & banner, sama seperti overlay)
        VStack(alignment: .leading) {
            Image(feedback.characterImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 400)
                .position(x: 190, y: 820)
        }

        // 6. Accuracy Percentage
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text("ACCURACY")
                .font(AppTypography.dmMono(size: 30))
                .foregroundStyle(AppColors.brownInk)

            Spacer()

            Text("\(accuracyPercent)%")
                .font(AppTypography.bungee(size: 69))
                .foregroundStyle(AppColors.brownInk)
        }
        .frame(width: 410, height: 160, alignment: .topLeading)
        .position(x: 475, y: 440)

        // 7. Statistik 3 Kolom (PERFECT, TOO EARLY, MISS)
        HStack(spacing: 0) {
            statColumn(count: result.perfectCount, label: "PERFECT")
            statColumn(count: result.tooEarlyCount, label: "TOO EARLY")
            statColumn(count: result.missCount, label: "MISS")
        }
        .frame(width: 700)
        .position(x: 490, y: 530)
    }

    // MARK: - Metric Column Helper
    private func statColumn(count: Int, label: String) -> some View {
        VStack(spacing: -10) {
            Text("\(count)")
                .font(AppTypography.dmMono(size: 50))
                .foregroundStyle(AppColors.brownInk)

            Text(label)
                .font(AppTypography.dmMono(size: 30))
                .foregroundStyle(AppColors.brownInk)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Replay Overlay
    @ViewBuilder
    private func replayOverlay(for replayResult: SessionResult) -> some View {
        let dismissReplay = {
            withAnimation(.easeInOut(duration: 0.35)) {
                activeReplayResult = nil
            }
            viewModel.send(.returnFromReplay)
        }

        if let makeReplayView {
            makeReplayView(replayResult, dismissReplay)
        } else {
            ZStack {
                AppColors.cream.ignoresSafeArea()

                VStack(spacing: 28) {
                    Text("SHOWTIME REPLAY")
                        .font(AppTypography.bungee(size: 48))
                        .foregroundStyle(AppColors.brownInk)

                    Text("\(songInfo.title) • \(replayResult.bpm) BPM")
                        .font(AppTypography.dmMono(size: 28))
                        .foregroundStyle(AppColors.brownInk.opacity(0.8))

                    Button {
                        dismissReplay()
                    } label: {
                        EmptyView()
                    }
                    .buttonStyle(
                        AssetButtonStyle(
                            normalAssetName: "Button_Back to Summary_Normal",
                            pressedAssetName: "Button_Back to Summary_Pressed",
                            size: CGSize(width: 360, height: 96)
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Scale-Only Button Style (No Opacity Fade)
private struct ScaleOnlyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .clicksWhenPressed(configuration.isPressed)
    }
}

// MARK: - Previews
#if DEBUG
private struct ShowtimeSummaryPreviewRepository: SessionRepository {
    func save(_ result: SessionResult) async throws {}
    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] { [] }
    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? { nil }
    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy: RecordSortCriterion
    ) async throws -> [SessionResult] { [] }
}

#Preview("Showtime Summary with Intro Overlay", traits: .landscapeLeft) {
    let repo = ShowtimeSummaryPreviewRepository()
    let sampleResult = SessionResult(
        id: UUID(),
        patternID: "foundation",
        songID: "twinkle",
        bpm: 96,
        accuracy: 0.92,
        perfectCount: 22,
        tooEarlyCount: 2,
        missCount: 0,
        createdAt: Date(),
        beatEvents: []
    )
    let vm = ShowtimeSummaryViewModel(result: sampleResult, repository: repo)
    ShowtimeSummaryView(
        viewModel: vm,
        songInfo: ShowtimeSongInfo(
            title: "Twinkle Star",
            durationLabel: "1 min 20 sec",
            chords: ["C", "G", "Am", "F"]
        ),
        showIntroOverlay: true
    )
}

#Preview("Showtime Summary Board (3 Stars / AWESOME)", traits: .landscapeLeft) {
    let repo = ShowtimeSummaryPreviewRepository()
    let sampleResult = SessionResult(
        id: UUID(),
        patternID: "foundation",
        songID: "twinkle",
        bpm: 96,
        accuracy: 0.92,
        perfectCount: 22,
        tooEarlyCount: 2,
        missCount: 0,
        createdAt: Date(),
        beatEvents: []
    )
    let vm = ShowtimeSummaryViewModel(result: sampleResult, repository: repo)
    ShowtimeSummaryView(
        viewModel: vm,
        songInfo: ShowtimeSongInfo(
            title: "Twinkle Twinkle Little Star",
            durationLabel: "1 min 20 sec",
            chords: ["C", "G", "Am", "F"]
        ),
        showIntroOverlay: false
    )
}

#Preview("Showtime Summary Board (1 Star)", traits: .landscapeLeft) {
    let repo = ShowtimeSummaryPreviewRepository()
    let sampleResult = SessionResult(
        id: UUID(),
        patternID: "foundation",
        songID: "twinkle",
        bpm: 96,
        accuracy: 0.55,
        perfectCount: 10,
        tooEarlyCount: 6,
        missCount: 8,
        createdAt: Date(),
        beatEvents: []
    )
    let vm = ShowtimeSummaryViewModel(result: sampleResult, repository: repo)
    ShowtimeSummaryView(
        viewModel: vm,
        songInfo: ShowtimeSongInfo(
            title: "Twinkle Star",
            durationLabel: "1 min 20 sec",
            chords: ["C", "G", "Am", "F"]
        ),
        showIntroOverlay: false
    )
}
#endif

