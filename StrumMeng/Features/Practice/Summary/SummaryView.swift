//
//  SummaryView.swift
//  StrumMeng
//
//  Created by Sharon Tan on 27/10/26.
//

import SwiftUI

struct SummaryView: View {
    let viewModel: SummaryViewModel
    var onNavigate: ((SummaryDestination) -> Void)?
    @State private var activeReplayResult: SessionResult?

    var body: some View {
        GeometryReader { proxy in
            let scale = max(
                proxy.size.width / AppLayout.referenceSize.width,
                proxy.size.height / AppLayout.referenceSize.height
            )

            ZStack {
                // 1. Background Penuh (Semua kotak & frame sudah ada di sini)
                Image("Summary_BG")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()

                // 2. Konten Teks & Tombol di atas Background
                mainCanvas
                    .frame(
                        width: AppLayout.referenceSize.width,
                        height: AppLayout.referenceSize.height
                    )
                    .scaleEffect(scale)
                    .frame(
                        width: AppLayout.referenceSize.width * scale,
                        height: AppLayout.referenceSize.height * scale
                    )

                // 3. Pop-up Rekomendasi (Muncul saat tombol Retry ditekan)
                if case .showingRecommendation(let recommendation) = viewModel.state {
                    BPMRecommendationOverlay(
                        recommendation: recommendation,
                        offTempoCount: viewModel.result.tooEarlyCount + viewModel.result.missCount,
                        onKeepPrevious: {
                            viewModel.send(.rejectRecommendation)
                        },
                        onStartRecommended: { _ in
                            viewModel.send(.acceptRecommendation)
                        }
                    )
                }

                // 4. Layar Replay (Slide)
                if let replayResult = activeReplayResult {
                    ReplayView(viewModel: ReplayViewModel(result: replayResult)) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            activeReplayResult = nil
                        }
                        viewModel.send(.returnFromReplay)
                    }
                    .transition(.slide)
                    .zIndex(100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: activeReplayResult != nil)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
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
            // JUDUL "SUMMARY" DI ATAS
            // 💡 Ubah y untuk geser ke atas/bawah
            headerTitle
                .position(x: 688, y: 120)

            // --- KOLOM KIRI ---
            leftColumnElements

            // --- KOLOM KANAN ---
            rightColumnElements
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
    }

    // MARK: - Header Title
    private var headerTitle: some View {
        OutlinedText(
            text: "SUMMARY",
            font: AppTypography.bungee(size: 70),
            foregroundColor: AppColors.white,
            outlineColor: AppColors.brownInk,
            outlineWidth: 6,
            shadowColor: AppColors.redAccent,
            shadowOffset: CGSize(width: 0, height: 0)
        )
    }

    // MARK: - Left Column Elements
    @ViewBuilder
    private var leftColumnElements: some View {
        let pattern = PatternCatalog.pattern(forID: viewModel.result.patternID)
        let patternName = pattern?.name ?? "Foundation Strum"
        let duration = pattern.map {
            PracticeSessionConfig.durationLabel(for: $0, bpm: viewModel.result.bpm)
        } ?? "1 min"

        // 1. Nama Pattern (di dalam kotak cokelat kiri, di bawah tulisan PRACTICE)
        VStack(alignment: .leading) {
            Spacer()
            Text(patternName.uppercased())
                .font(AppTypography.bungee(size: 40))
                .foregroundStyle(AppColors.white)
                .lineSpacing(4)
        }
        .frame(width: 320, height: 180, alignment: .bottomLeading)
        .position(x: 236, y: 500)

        // 2. Baris Durasi & BPM (di bawah kotak cokelat)
        // 💡 Atur x dan y untuk geser baris durasi & BPM
        HStack(alignment: .firstTextBaseline) {
            Text(duration)
                .font(AppTypography.dmMono(size: 30))
                .foregroundStyle(AppColors.brownInk)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("BPM")
                    .font(AppTypography.dmMono(size: 30))
                    .foregroundStyle(AppColors.brownInk)

                Text("\(viewModel.result.bpm)")
                    .font(AppTypography.dmMono(size: 50))
                    .foregroundStyle(AppColors.brownInk)
            }
        }
        .frame(width: 355)
        .position(x: 236, y: 700)

        // 3. Tombol "BACK TO MAIN" (di area bawah kiri)
        // 💡 Atur x dan y untuk posisikan tombol back
        Button {
            viewModel.send(.tapBackToMain)
        } label: {
            Image("Button_Back to Main")
                .resizable()
                .scaledToFit()
                .frame(width: 340, height: 42)
        }
        .buttonStyle(ScaleOnlyButtonStyle())
        .position(x: 232, y: 955)
    }

    // MARK: - Right Column Elements (Tanpa Background Tambahan)
    @ViewBuilder
    private var rightColumnElements: some View {
        let result = viewModel.result
        let offTempoCount = result.tooEarlyCount + result.missCount
        let accuracyPercent = Int((result.accuracy * 100).rounded())

        let headlineText: String = {
            if result.accuracy >= 0.86 {
                return "PERFECT"
            } else if result.accuracy >= 0.66 {
                return "GOOD JOB"
            } else {
                return "KEEP GOING"
            }
        }()

        // 1. Header Banner Kanan ("AWESOME" & Panah >>>)
        // 💡 Atur posisi y untuk sejajar di banner cokelat atas
        VStack(alignment: .leading) {
            Text(headlineText)
                .font(AppTypography.bungee(size: 70))
                .foregroundStyle(AppColors.white)
                .lineSpacing(4)
                .padding(.bottom, 50)
            
            Spacer()
            
            Text(
                offTempoCount > 0
                    ? "BUT YOU OFF TEMPO \(offTempoCount) TIMES."
                    : "ALL ON TEMPO! PERFECT RHYTHM."
            )
            .font(AppTypography.bungee(size: 40))
            .foregroundStyle(AppColors.brownInk)
            
            
        }
        .frame(width: 730, height: 160, alignment: .topLeading)
        .position(x: 919, y: 370)

        // 3. Accuracy Pill Capsule (di tengah area teal)
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text("ACCURACY")
                .font(AppTypography.dmMono(size: 30))
                .foregroundStyle(AppColors.brownInk)

            Text("\(accuracyPercent)%")
                .font(AppTypography.bungee(size: 70))
                .foregroundStyle(AppColors.brownInk)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 14)
        .position(x: 919, y: 635)

        // 4. Statistik 3 Kolom (PERFECT, TOO EARLY, MISS)
        HStack(spacing: 0) {
            statColumn(count: result.perfectCount, label: "PERFECT")
            statColumn(count: result.tooEarlyCount, label: "TOO EARLY")
            statColumn(count: result.missCount, label: "MISS")
        }
        .frame(width: 700)
        .position(x: 919, y: 770)

        // 5. Tombol REPLAY & RETRY (di bawah area teal)
        // 💡 Atur posisi y untuk menaikkan/menurunkan kedua tombol ini
        HStack(spacing: 24) {
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
        .position(x: 919, y: 940)
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
}

// MARK: - Scale-Only Button Style (No Opacity Fade)
private struct ScaleOnlyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Previews
private struct PreviewSessionRepository: SessionRepository {
    func save(_ result: SessionResult) async throws {}
    func practiceRecords(forPattern patternID: String) async throws -> [SessionResult] { [] }
    func lastPracticeBPM(forPattern patternID: String) async throws -> Int? { nil }
    func topRecords(
        patternID: String,
        limit: Int?,
        sortedBy: RecordSortCriterion
    ) async throws -> [SessionResult] { [] }
}

#Preview("Main Summary") {
    let repo = PreviewSessionRepository()
    let sampleResult = SessionResult(
        id: UUID(),
        patternID: "syncopation",
        songID: nil,
        bpm: 100,
        accuracy: 0.90,
        perfectCount: 15,
        tooEarlyCount: 1,
        missCount: 0,
        createdAt: Date(),
        beatEvents: []
    )
    let vm = SummaryViewModel(result: sampleResult, repository: repo)
    SummaryView(viewModel: vm)
}

#Preview("Summary with Recommendation", traits: .landscapeLeft) {
    let repo = PreviewSessionRepository()
    let sampleResult = SessionResult(
        id: UUID(),
        patternID: "syncopation",
        songID: nil,
        bpm: 70,
        accuracy: 0.45,
        perfectCount: 10,
        tooEarlyCount: 4,
        missCount: 3,
        createdAt: Date(),
        beatEvents: []
    )
    let vm = SummaryViewModel(result: sampleResult, repository: repo)
    let _ = vm.send(.tapRetry)
    SummaryView(viewModel: vm)
}

