import SwiftUI

/// Practice-Play screen, edge to edge. The Play_BG artwork provides the header box, the red board and
/// the lane; on top of it the code draws the pause button, title, BPM, the moving lane contents,
/// session time and progress. READY?, the count-in and the pause modal draw over a veil.
///
/// Only the parts that move (lane, time, progress, count-in number) are redrawn every frame; the
/// artwork, title, BPM and buttons are drawn once and only change with the phase. That keeps each
/// frame cheap and the buttons' touch handling stable while the lane scrolls.
struct PracticePlayView: View {
    /// 60 fps is smooth enough. On a 120 Hz iPad an uncapped timeline draws twice as often, and the
    /// main thread then handles strums (especially from the iPhone) later. Same cap as the prototype.
    private static let frameInterval: TimeInterval = 1.0 / 60

    private let liveModel: () -> PlayScreenModel
    private let isAnimating: Bool
    private let onReady: () -> Void
    private let onPause: () -> Void
    private let onResume: () -> Void
    private let onRestart: () -> Void
    private let onBackToMenu: () -> Void

    /// A still frame (previews, the hit-animation gallery, a caller with its own timeline).
    init(model: PlayScreenModel,
         onReady: @escaping () -> Void = {},
         onPause: @escaping () -> Void = {},
         onResume: @escaping () -> Void = {},
         onRestart: @escaping () -> Void = {},
         onBackToMenu: @escaping () -> Void = {}) {
        self.init(isAnimating: false, liveModel: { model }, onReady: onReady,
                  onPause: onPause, onResume: onResume, onRestart: onRestart, onBackToMenu: onBackToMenu)
    }

    /// A live session: `liveModel` is read every frame while `isAnimating`, for the moving parts only.
    init(isAnimating: Bool,
         liveModel: @escaping () -> PlayScreenModel,
         onReady: @escaping () -> Void = {},
         onPause: @escaping () -> Void = {},
         onResume: @escaping () -> Void = {},
         onRestart: @escaping () -> Void = {},
         onBackToMenu: @escaping () -> Void = {}) {
        self.liveModel = liveModel
        self.isAnimating = isAnimating
        self.onReady = onReady
        self.onPause = onPause
        self.onResume = onResume
        self.onRestart = onRestart
        self.onBackToMenu = onBackToMenu
    }

    var body: some View {
        GeometryReader { geo in
            let layout = PlayScreenLayout(size: geo.size)
            // Read once per state change (phase, title, BPM), not once per frame.
            let model = liveModel()
            ZStack(alignment: .topLeading) {
                Image("Play_BG")
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                TimelineView(.animation(minimumInterval: Self.frameInterval, paused: !isAnimating)) { _ in
                    board(layout, liveModel())
                }
                header(layout, model)
                veil(layout, model)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.easeOut(duration: 0.2), value: model.phase)
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    // MARK: Header (static)

    private func header(_ layout: PlayScreenLayout, _ model: PlayScreenModel) -> some View {
        ZStack(alignment: .topLeading) {
            PauseButton(size: layout.pauseSize, isPaused: model.phase == .paused, action: onPause)
                .position(layout.pauseCenter)

            OutlinedText(text: model.title.uppercased(), font: AppFont.display(layout.titleFontSize),
                         foregroundColor: AppColor.titleText, outlineColor: AppColor.ink,
                         outlineWidth: layout.titleFontSize * 0.07, shadowColor: .clear, shadowOffset: .zero,
                         alignment: .center)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: layout.titleMaxWidth)
                .position(layout.titleCenter)

            Text("BPM \(model.bpm)")
                .font(AppFont.mono(layout.bpmFontSize))
                .foregroundStyle(AppColor.ink)
                .fixedSize()
                .frame(width: layout.size.width - layout.bpmTrailing, alignment: .trailing)
                .position(x: (layout.size.width - layout.bpmTrailing) / 2, y: layout.bpmCenterY)
        }
    }

    // MARK: Board (every frame)

    private func board(_ layout: PlayScreenLayout, _ model: PlayScreenModel) -> some View {
        let u = layout.unit
        return ZStack(alignment: .topLeading) {
            PlayLaneView(model: model, layout: layout)
                .offset(x: layout.laneRect.minX, y: layout.laneRect.minY)

            Text(PlayTimeline.clockLabel(songTime: model.songTime, duration: model.duration))
                .font(AppFont.mono(layout.clockFontSize))
                .foregroundStyle(AppColor.ink)
                .fixedSize()
                .offset(x: layout.progressRect.minX + 10 * u, y: layout.clockLabelTop)

            PlayProgressView(progress: PlayTimeline.progress(songTime: model.songTime, duration: model.duration),
                             strokeWidth: 3 * u)
                .frame(width: layout.progressRect.width, height: layout.progressRect.height)
                .offset(x: layout.progressRect.minX, y: layout.progressRect.minY)
        }
    }

    // MARK: Veil (READY?, count-in, pause)

    @ViewBuilder
    private func veil(_ layout: PlayScreenLayout, _ model: PlayScreenModel) -> some View {
        switch model.phase {
        case .ready:
            ZStack(alignment: .topLeading) {
                AppColor.dim.opacity(0.55)
                PlayCalloutView(text: "READY?", fontSize: 54 * layout.unit)
                    .position(layout.calloutCenter)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onReady)
            .transition(.opacity)
        case .countIn(let number):
            ZStack(alignment: .topLeading) {
                AppColor.dim.opacity(0.55)
                // Only the number's pop animation needs the per-frame time.
                TimelineView(.animation(minimumInterval: Self.frameInterval, paused: !isAnimating)) { _ in
                    let frame = liveModel()
                    PlayCalloutView(
                        text: "\(number)",
                        fontSize: 140 * layout.unit,
                        beatProgress: PlayTimeline.countInBeatProgress(songTime: frame.songTime,
                                                                       slotInterval: frame.slotInterval))
                        .position(layout.calloutCenter)
                }
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        case .paused:
            ZStack {
                AppColor.dim.opacity(0.6)
                PauseMenuOverlay(unit: layout.unit, onResume: onResume, onRestart: onRestart,
                                 onBackToMenu: onBackToMenu)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            .transition(.opacity)
        case .playing:
            EmptyView()
        }
    }
}
