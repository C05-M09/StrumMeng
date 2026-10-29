import SwiftUI

// Adjust Listen positions and sizes here while the Canvas preview is open.
enum ListenLayout {
    static let size = CGSize(width: 1376, height: 1032)
    static let firstX: CGFloat = 194
    static let slot: CGFloat = 142
    static let railY: CGFloat = 542
    static let node: CGFloat = 122
    static let ring: CGFloat = 138
    static let countY: CGFloat = 666
    static let readyCenter = CGPoint(x: 1140, y: 884)
    static let readySize = CGSize(width: 294, height: 116)
    static let trackWidth: CGFloat = 1140
    static let trackHeight: CGFloat = 30
    static let trackCenterX: CGFloat = 690
    static let informationTravel: CGFloat = 90
    static let informationDuration: Double = 0.42
    static let informationStagger: Double = 0.08
    static let titleLineSpacing: CGFloat = -20
    static let informationBannerSize = CGSize(width: 1500, height: 616)
    static let informationBannerCenter = CGPoint(x: 688, y: 516)
    static let informationCharacterSize = CGSize(width: 960, height: 1020)
    static let informationCharacterCenter = CGPoint(x: 450, y: 620)
    static let informationBubbleSize = CGSize(width: 850, height: 320)
    static let informationBubbleCenter = CGPoint(x: 895, y: 680)
    static let informationTextCenter = CGPoint(x: 925, y: 675)
    static let informationNextCenter = CGPoint(x: 1190, y: 825)
}

struct ListenView: View {
    @State private var viewModel: ListenViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var informationVisible = false
    
    init(viewModel: ListenViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let scale = max(geometry.size.width / ListenLayout.size.width,
                            geometry.size.height / ListenLayout.size.height)
            ZStack {
                Image("Play_BG").resizable()
                header
                notation
                readyButton
                if viewModel.state == .information {
                    information.transition(.opacity)
                }
                if case .paused = viewModel.state { pauseMenu }
                if case let .failed(message) = viewModel.state {
                    AppColors.brownInk.opacity(0.8)
                    VStack(spacing: 24) {
                        Text(message).font(AppTypography.dmMono(size: 24))
                        Button("Try again") { viewModel.send(.restart) }
                        Button("Back to patterns") { viewModel.send(.back) }
                    }.foregroundStyle(AppColors.cream)
                }
            }
            .frame(width: ListenLayout.size.width, height: ListenLayout.size.height)
            .scaleEffect(scale)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .statusBarHidden()
        .onAppear { informationVisible = true }
        .animation(.easeOut(duration: 0.18), value: viewModel.state == .information)
        .onDisappear { viewModel.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { viewModel.send(.pause) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .listenAudioInterrupted)) { _ in
            viewModel.send(.pause)
        }
    }
    
    private var header: some View {
        ZStack {
            VStack(spacing: ListenLayout.titleLineSpacing) {
                ForEach(viewModel.pattern.name.uppercased()
                    .replacingOccurrences(of: " STRUM", with: "\nSTRUM")
                    .components(separatedBy: "\n"), id: \.self) { line in
                    OutlinedText(text: line,
                         font: AppTypography.bungee(size: 66), foregroundColor: AppColors.white,
                         outlineColor: AppColors.brownInk, outlineWidth: 6,
                         shadowColor: AppColors.brownInk, shadowOffset: .zero, alignment: .center)
                }
            }
            .frame(width: 790).position(x: 688, y: 100)
            Text("BPM \(viewModel.bpm)").font(AppTypography.dmMono(size: 44))
                .foregroundStyle(AppColors.brownInk).position(x: 1210, y: 105)
            assetButton("Pause", normal: "Button_Pause_Normal", pressed: "Button_Pause_Pressed",
                        size: CGSize(width: 90, height: 98)) { viewModel.send(.pause) }
                .position(x: 110, y: 109)
        }
    }
    
    private var notation: some View {
        ZStack {
            // Same rail geometry and design token as PlayLaneView, underneath every slot.
            Rectangle()
                .fill(AppColor.track)
                .frame(width: ListenLayout.trackWidth, height: ListenLayout.trackHeight)
                .position(x: ListenLayout.trackCenterX, y: ListenLayout.railY)
                .allowsHitTesting(false)
            ForEach(Array(viewModel.pattern.strokes.enumerated()), id: \.offset) { index, stroke in
                let x = ListenLayout.firstX + CGFloat(index) * ListenLayout.slot
                if stroke != .rest {
                    Image(stroke == .down ? "Play_Arrow_Down" : "Play_Arrow_Up")
                        .resizable().scaledToFit()
                        .frame(width: ListenLayout.node, height: ListenLayout.node)
                        .position(x: x, y: ListenLayout.railY)
                }
                Text(viewModel.pattern.beatLabels[index])
                    .font(AppTypography.dmMono(size: 32)).foregroundStyle(AppColors.cream)
                    .position(x: x, y: ListenLayout.countY)
            }
            if viewModel.state != .information {
                Circle().stroke(AppColors.perfect, lineWidth: 5)
                    .frame(width: ListenLayout.ring, height: ListenLayout.ring)
                    .position(x: ListenLayout.firstX + CGFloat(viewModel.state.step) * ListenLayout.slot,
                              y: ListenLayout.railY)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var readyButton: some View {
        assetButton("Ready", normal: viewModel.state.canProceed ? "Button_Ready_Normal" : "Button_Ready_Disabled",
                    pressed: "Button_Ready_Pressed", size: ListenLayout.readySize) {
            viewModel.send(.ready)
        }
                    .disabled(!viewModel.state.canProceed)
                    .position(ListenLayout.readyCenter)
    }
    
    private var information: some View {
        ZStack {
            AppColors.brownInk.opacity(0.9)
            Image("Listen_Box").resizable()
                .frame(width: ListenLayout.informationBannerSize.width,
                       height: ListenLayout.informationBannerSize.height)
                .position(ListenLayout.informationBannerCenter)
                .modifier(informationEntrance(y: ListenLayout.informationTravel / 3))
                .allowsHitTesting(false)
            Image("Retry_Character").resizable().scaledToFit()
                .frame(width: ListenLayout.informationCharacterSize.width,
                       height: ListenLayout.informationCharacterSize.height)
                .position(ListenLayout.informationCharacterCenter)
                .modifier(informationEntrance(delay: 0.08, x: -ListenLayout.informationTravel))
            Group {
                Image("Listen_Bubble").resizable().scaledToFit()
                    .frame(width: ListenLayout.informationBubbleSize.width,
                           height: ListenLayout.informationBubbleSize.height)
                    .position(ListenLayout.informationBubbleCenter)
                VStack(spacing: 2) {
                    Text("Read and listen to the pattern,")
                    Text("then strum along when you’re ready.")
                    Text("\(Text("No chords needed,").foregroundStyle(AppColors.redAccent)) just the rhythm.")
                }
                    .font(AppTypography.dmMono(size: 28)).multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.brownInk)
                    .frame(width: 720).position(ListenLayout.informationTextCenter)
            }
            .modifier(informationEntrance(delay: ListenLayout.informationStagger * 2,
                                          y: ListenLayout.informationTravel / 3))
            assetButton("Next", normal: "Button_Next_Normal", pressed: "Button_Next_Pressed",
                        size: CGSize(width: 252, height: 112)) { viewModel.send(.next) }
                .position(ListenLayout.informationNextCenter)
                .modifier(informationEntrance(delay: ListenLayout.informationStagger * 3,
                                              y: ListenLayout.informationTravel / 4))
        }
    }
    
    private func informationEntrance(delay: Double = 0, x: CGFloat = 0,
                                     y: CGFloat = 0) -> ListenInformationEntrance {
        ListenInformationEntrance(visible: informationVisible, reduceMotion: reduceMotion,
                                  duration: ListenLayout.informationDuration, delay: delay, x: x, y: y)
    }
    
    private var pauseMenu: some View {
        ZStack {
            AppColors.brownInk.opacity(0.65)
            Image("Option_Card").resizable().scaledToFit()
                .frame(width: 800, height: 720)
            VStack(spacing: 20) {
                Text("ARE YOU SURE YOU WANT\nTO END THE SESSION?")
                    .font(AppTypography.bungee(size: 45)).multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.brownInk).padding(.bottom, 12)
                assetButton("Resume", normal: "Button_Resume_Normal", pressed: "Button_Resume_Pressed",
                            size: CGSize(width: 510, height: 88)) { viewModel.send(.resume) }
                assetButton("Restart", normal: "Button_Restart_Normal", pressed: "Button_Restart_Pressed",
                            size: CGSize(width: 510, height: 88)) { viewModel.send(.restart) }
                assetButton("Back to Menu", normal: "Button_Back to Menu_Normal", pressed: "Button_Back to Menu_Pressed",
                            size: CGSize(width: 510, height: 88)) { viewModel.send(.back) }
            }
        }
    }
    
    private func assetButton(_ label: String, normal: String, pressed: String, size: CGSize,
                             action: @escaping () -> Void) -> some View {
        Button(label, action: action).buttonStyle(AssetButtonStyle(
            normalAssetName: normal, pressedAssetName: pressed, size: size))
        .accessibilityLabel(label)
    }
}

#if DEBUG
#Preview("01 · Information", traits: .landscapeLeft) {
    ListenPreviewFactory.make(events: [])
}
#Preview("02 · Listening — middle of first loop", traits: .landscapeLeft) {
    ListenPreviewFactory.make(events: [.next], elapsed: 1.125)
}
#Preview("03 · Listening — Ready enabled", traits: .landscapeLeft) {
    ListenPreviewFactory.make(events: [.next, .progress(step: 3, completed: true)], elapsed: 1.125)
}
#Preview("04 · Pause", traits: .landscapeLeft) {
    ListenPreviewFactory.make(events: [.next, .progress(step: 3, completed: false), .pause])
}
#Preview("05 · Playback error", traits: .landscapeLeft) {
    ListenPreviewFactory.make(events: [.failed("The guitar example couldn’t play. Please try again.")])
}
#endif
