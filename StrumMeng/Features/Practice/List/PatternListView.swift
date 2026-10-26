import SwiftUI

struct PatternListView: View {
    let viewModel: PatternListViewModel
    
    var body: some View {
        GeometryReader { proxy in
            let scale = max(
                proxy.size.width / AppLayout.referenceSize.width,
                proxy.size.height / AppLayout.referenceSize.height
            )
            
            ZStack {
                Image("Practice_BG")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                
                content
                    .frame(
                        width: AppLayout.referenceSize.width,
                        height: AppLayout.referenceSize.height
                    )
                    .scaleEffect(scale)
                    .frame(
                        width: AppLayout.referenceSize.width * scale,
                        height: AppLayout.referenceSize.height * scale
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .empty:
            Text("No strumming patterns available")
                .font(AppTypography.dmMono(size: 20))
                .foregroundStyle(AppColors.cream)
            
        case let .loaded(patterns, selectedPatternID, selectedBPM):
            if let selectedPattern = patterns.first(where: { $0.id == selectedPatternID }) {
                ZStack {
                    PatternWheelView(
                        patterns: patterns,
                        selectedPatternID: selectedPatternID,
                        onSelect: { id in
                            viewModel.send(.selectPattern(id: id))
                        }
                    )
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(
                                        color: AppColors.brownSecondary.opacity(1),
                                        location: 0.0
                                    ),
                                    .init(
                                        color: AppColors.brownPrimary.opacity(0.88),
                                        location: 0.48
                                    ),
                                    .init(
                                        color: AppColors.brownPrimary.opacity(0.44),
                                        location: 0.78
                                    ),
                                    .init(
                                        color: .clear,
                                        location: 1.0
                                    )
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: AppLayout.referenceSize.width,
                            height: 210
                        )
                        .blur(radius: 12)
                        .position(x: 670, y: 92)
                        .allowsHitTesting(false)
                    
                    OutlinedText(
                        text: "PRACTICE",
                        font: AppTypography.bungee(size: 70),
                        foregroundColor: AppColors.white,
                        outlineColor: AppColors.brownInk,
                        outlineWidth: 7,
                        shadowColor: AppColors.redAccent,
                        shadowOffset: CGSize(width: 0, height: 9)
                    )
                    .frame(width: 560, height: 115)
                    .position(x: 688, y: 104)
                    .allowsHitTesting(false)
                    
                    PatternCardView(
                        pattern: selectedPattern,
                        bpm: selectedBPM,
                        onDecreaseBPM: { viewModel.send(.decreaseBPM) },
                        onIncreaseBPM: { viewModel.send(.increaseBPM) }
                    )
                    .id(selectedPatternID)
                    .transition(
                        .scale(scale: 0.965)
                        .combined(with: .opacity)
                    )
                    .position(x: 1_010, y: 580)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.84),
                        value: selectedPatternID
                    )
                    
                    Button {
                        viewModel.send(.tapBack)
                    } label: {
                        Color.clear
                    }
                    .buttonStyle(
                        AssetButtonStyle(
                            normalAssetName: "Button_Back_Normal",
                            pressedAssetName: "Button_Back_Pressed",
                            size: CGSize(width: 88.46, height: 95.85)
                        )
                    )
                    .position(x: 109, y: 103)
                    .accessibilityLabel("Back")
                    
                    Button {
                        viewModel.send(.tapPlay)
                    } label: {
                        Color.clear
                    }
                    .buttonStyle(
                        AssetButtonStyle(
                            normalAssetName: "Button_Play_Normal",
                            pressedAssetName: "Button_Play_Pressed",
                            size: CGSize(width: 122.71, height: 131.93)
                        )
                    )
                    .position(x: 1_292, y: 928)
                    .accessibilityLabel("Listen to \(selectedPattern.name)")
                    .accessibilityHint("Opens Listen at \(selectedBPM) BPM")
                }
                .frame(
                    width: AppLayout.referenceSize.width,
                    height: AppLayout.referenceSize.height
                )
                .clipped()
            }
        }
    }
}

#Preview {
    PatternListView(
        viewModel: PatternListViewModel(
            onListenRequested: { _, _ in },
            onBackRequested: {}
        )
    )
}
