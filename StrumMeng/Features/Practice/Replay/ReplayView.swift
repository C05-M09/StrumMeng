//
//  ReplayView.swift
//  StrumMeng
//
//  Created by Sharon Tan on 29/10/26.
//

import SwiftUI

/// Layar Replay (US4) untuk memutar ulang sesi latihan yang telah selesai.
///
/// Karakteristik utama Replay:
/// - Menampilkan kembali pergerakan panah dan feedback warna hasil (`.perfect`, `.tooEarly`, `.miss`)
///   secara visual sesuai waktu aslinya.
/// - Tidak ada penilaian ulang (*no re-judging*) dan tidak menerima input mic/controller.
/// - Kontrol dasar: Play, Pause, Restart, dan tombol Kembali ke Summary.
struct ReplayView: View {
    @State private var viewModel: ReplayViewModel
    var onDismiss: (() -> Void)?

    init(viewModel: ReplayViewModel, onDismiss: (() -> Void)? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geo in
            let scale = max(
                geo.size.width / AppLayout.referenceSize.width,
                geo.size.height / AppLayout.referenceSize.height
            )
            let layout = PlayScreenLayout(size: geo.size)
            let model = viewModel.screenModel()

            ZStack(alignment: .topLeading) {
                // 1. Background Penuh (Play_BG)
                Image("Play_BG")
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)

                // 2. Konten Rel Panah yang Bergerak (Dijalankan via TimelineView animasi per-frame)
                TimelineView(.animation(minimumInterval: nil, paused: !viewModel.isAnimating)) { _ in
                    board(layout, viewModel.screenModel())
                }

                // 3. Header: Tombol Back, Judul Pattern, dan Info BPM
                header(layout, model)

                // 4. Lapisan Overlay (Ready, Paused, Finished)
                overlays(layout, scale: scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.easeOut(duration: 0.2), value: viewModel.state)
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: viewModel.state) { _, newState in
            if newState == .dismissed || newState == .finished {
                onDismiss?()
            }
        }
    }

    // MARK: - Header

    private func header(_ layout: PlayScreenLayout, _ model: PlayScreenModel) -> some View {
        let u = layout.unit
        return ZStack(alignment: .topLeading) {
            // Tombol Pause di pojok kiri atas (sesuai ListenView & Play)
            Button("Pause") {
                withAnimation(.easeOut(duration: 0.2)) {
                    if viewModel.state == .playing {
                        viewModel.send(.pause)
                    } else if viewModel.state == .paused {
                        viewModel.send(.resume)
                    }
                }
            }
            .buttonStyle(
                AssetButtonStyle(
                    normalAssetName: "Button_Pause_Normal",
                    pressedAssetName: "Button_Pause_Pressed",
                    size: CGSize(width: 90 * (layout.pauseSize / 86), height: 98 * (layout.pauseSize / 86))
                )
            )
            .position(layout.pauseCenter)

            // Judul Replay & Nama Pattern di tengah atas
            OutlinedText(
                text: "REPLAY: \(model.title.uppercased())",
                font: AppFont.display(layout.titleFontSize * 0.85),
                foregroundColor: AppColor.titleText,
                outlineColor: AppColor.ink,
                outlineWidth: layout.titleFontSize * 0.06,
                shadowColor: .clear,
                shadowOffset: .zero,
                alignment: .center
            )
            .minimumScaleFactor(0.5)
            .frame(maxWidth: layout.titleMaxWidth)
            .position(layout.titleCenter)

            // Indikator BPM di kanan atas
            Text("BPM \(model.bpm)")
                .font(AppFont.mono(layout.bpmFontSize))
                .foregroundStyle(AppColor.ink)
                .fixedSize()
                .frame(width: layout.size.width - layout.bpmTrailing, alignment: .trailing)
                .position(x: (layout.size.width - layout.bpmTrailing) / 2, y: layout.bpmCenterY)
        }
    }

    // MARK: - Board (Rel Panah, Waktu & Progress Bar)

    private func board(_ layout: PlayScreenLayout, _ model: PlayScreenModel) -> some View {
        let u = layout.unit
        return ZStack(alignment: .topLeading) {
            // Jalur rel dan node panah
            PlayLaneView(model: model, layout: layout)
                .offset(x: layout.laneRect.minX, y: layout.laneRect.minY)

            // Waktu lagu (misal: "00:05 / 00:30")
            Text(viewModel.clockLabel)
                .font(AppFont.mono(layout.clockFontSize))
                .foregroundStyle(AppColor.ink)
                .fixedSize()
                .offset(x: layout.progressRect.minX + 10 * u, y: layout.clockLabelTop)

            // Garis progres playback
            PlayProgressView(progress: viewModel.progress, strokeWidth: 3 * u)
                .frame(width: layout.progressRect.width, height: layout.progressRect.height)
                .offset(x: layout.progressRect.minX, y: layout.progressRect.minY)
        }
    }

    // MARK: - Lapisan Overlay (Ready, Paused, Finished)

    @ViewBuilder
    private func overlays(_ layout: PlayScreenLayout, scale: CGFloat) -> some View {
        switch viewModel.state {
        case .ready:
            ReplayReadyOverlay {
                withAnimation(.easeOut(duration: 0.25)) {
                    viewModel.send(.play)
                }
            }
            .transition(.opacity)

        case .paused:
            pauseMenu(scale: scale)

        case .finished, .playing, .dismissed:
            EmptyView()
        }
    }

    // MARK: - Pause Menu (Sama persis seperti ListenView.pauseMenu)
    private func pauseMenu(scale: CGFloat) -> some View {
        ZStack {
            AppColors.brownInk.opacity(0.65)
                .ignoresSafeArea()

            ZStack {
                Image("Option_Card")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 800, height: 720)

                VStack(spacing: 20) {
                    Text("ARE YOU SURE YOU WANT\nTO END THE SESSION?")
                        .font(AppTypography.bungee(size: 45))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColors.brownInk)
                        .padding(.bottom, 12)

                    Button("Resume") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.send(.resume)
                        }
                    }
                    .buttonStyle(
                        AssetButtonStyle(
                            normalAssetName: "Button_Resume_Normal",
                            pressedAssetName: "Button_Resume_Pressed",
                            size: CGSize(width: 510, height: 88)
                        )
                    )

                    Button("Restart") {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.send(.restart)
                        }
                    }
                    .buttonStyle(
                        AssetButtonStyle(
                            normalAssetName: "Button_Restart_Normal",
                            pressedAssetName: "Button_Restart_Pressed",
                            size: CGSize(width: 510, height: 88)
                        )
                    )

                    Button("Back to Menu") {
                        viewModel.send(.backToSummary)
                    }
                    .buttonStyle(
                        AssetButtonStyle(
                            normalAssetName: "Button_Back to Menu_Normal",
                            pressedAssetName: "Button_Back to Menu_Pressed",
                            size: CGSize(width: 510, height: 88)
                        )
                    )
                }
            }
            .scaleEffect(scale)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

}

// MARK: - Previews for Every State (CLAUDE.md §8)

#Preview("1. Ready State") {
    let result = SessionResultBuilder.build(
        id: UUID(),
        patternID: "foundation",
        bpm: 80,
        beatEvents: [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0),
            BeatEvent(stepIndex: 2, result: .tooEarly, offsetMs: -10),
        ],
        createdAt: Date()
    )
    ReplayView(viewModel: ReplayViewModel(result: result))
}

#Preview("2. Playing State") {
    let result = SessionResultBuilder.build(
        id: UUID(),
        patternID: "foundation",
        bpm: 80,
        beatEvents: [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0),
            BeatEvent(stepIndex: 2, result: .tooEarly, offsetMs: -40),
            BeatEvent(stepIndex: 4, result: .miss, offsetMs: nil)
        ],
        createdAt: Date()
    )
    let vm = ReplayViewModel(result: result)
    vm.send(.play)
    vm.advanceTime(by: 1.5)
    return ReplayView(viewModel: vm)
}

#Preview("3. Paused State") {
    let result = SessionResultBuilder.build(
        id: UUID(),
        patternID: "foundation",
        bpm: 80,
        beatEvents: [],
        createdAt: Date()
    )
    let vm = ReplayViewModel(result: result)
    vm.send(.play)
    vm.send(.pause)
    return ReplayView(viewModel: vm)
}

#Preview("4. Finished State") {
    let result = SessionResultBuilder.build(
        id: UUID(),
        patternID: "foundation",
        bpm: 80,
        beatEvents: [
            BeatEvent(stepIndex: 0, result: .perfect, offsetMs: 0),
            BeatEvent(stepIndex: 2, result: .perfect, offsetMs: 10),
            BeatEvent(stepIndex: 4, result: .tooEarly, offsetMs: -80)
        ],
        createdAt: Date()
    )
    let vm = ReplayViewModel(result: result)
    vm.send(.play)
    vm.advanceTime(by: vm.duration + 1.0)
    return ReplayView(viewModel: vm)
}
