//
//  GuidebookTempoControlView.swift
//  StrumMeng
//
//  Created by sharon on 30/10/26.
//

import SwiftUI

/// The interactive controls placed in the blank area of Guidebook Page 2 (Practice Tempo).
/// Contains the 8-stroke alternate strum diagram, the BPM stepper (60–120 in steps of 5),
/// and the audio preview toggle button.
struct GuidebookTempoControlView: View {
    @Bindable var viewModel: GuidebookViewModel

    var body: some View {
        
        VStack(alignment: .leading, spacing: 14) {
            // 8-beat strum diagram asset with active playback highlight
            tempoDiagram
                
            Spacer()
            
            // BPM Stepper and Audio Preview Row
            HStack(spacing: 12) {
                // Decrease BPM button (-)
                Button {
                    viewModel.decreaseBPM()
                } label: {
                    Text("−")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppColors.brownInk)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                        )
                }
                .disabled(!viewModel.canDecreaseBPM)
                .opacity(viewModel.canDecreaseBPM ? 1.0 : 0.35)
                .accessibilityLabel("Decrease BPM")

                // BPM value display (tanpa background kotak)
                Text("\(viewModel.bpm)")
                    .font(AppTypography.dmMono(size: 28).bold())
                    .foregroundStyle(AppColors.brownInk)
                    .frame(minWidth: 48)
                    .accessibilityLabel("Current tempo \(viewModel.bpm) BPM")
                    .padding(.horizontal, 8)

                // Increase BPM button (+)
                Button {
                    viewModel.increaseBPM()
                } label: {
                    Text("+")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColors.brownInk)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                        )
                }
                .disabled(!viewModel.canIncreaseBPM)
                .opacity(viewModel.canIncreaseBPM ? 1.0 : 0.35)
                .accessibilityLabel("Increase BPM")

                // Audio preview button (Speaker icon)
                Button {
                    viewModel.toggleSoundPreview()
                } label: {
                    Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColors.brownInk)
                        .frame(width: 44, height: 36)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(viewModel.isPlayingAudio ? "Stop tempo audio" : "Play tempo audio")
                .padding(.leading, 12)
            }
            .padding(.leading, 100)
            
            
        }
        .frame(width: 540, height: 190)
//        .background(AppColors.brownPrimary.opacity(0.75))
        Spacer()
    }

    private var tempoDiagram: some View {
        let diagramWidth: CGFloat = 530
        let svgWidth: CGFloat = 551.87
        let svgHeight: CGFloat = 109.26
        let scale = diagramWidth / svgWidth
        let diagramHeight = svgHeight * scale

        return ZStack(alignment: .topLeading) {
            // Highlight backing card positioned BEHIND Image("Guidebook_Tempo")
            if viewModel.isPlayingAudio, let currentStep = viewModel.currentStep {
                let boxWidth: CGFloat = 56.8 * scale
                let boxHeight: CGFloat = 73.16 * scale
                let boxY: CGFloat = 32.09 * scale
                let boxX: CGFloat = (4.0 + CGFloat(currentStep) * 69.647) * scale
                let cornerRadius: CGFloat = 8.64 * scale
                let padding: CGFloat = 5

                ZStack(alignment: .bottom) {
                    // Solid golden-yellow backing card framing the box from behind
                    RoundedRectangle(cornerRadius: cornerRadius + padding)
                        .fill(AppColors.recordOutline)

                }
                .frame(width: boxWidth + (padding * 2), height: boxHeight + (padding * 2))
                .shadow(color: AppColors.recordOutline.opacity(0.85), radius: 8, x: 0, y: 0)
                .shadow(color: AppColors.brownInk.opacity(0.2), radius: 2, y: 2)
                .scaleEffect(1.04)
                .offset(x: boxX - padding, y: boxY - padding)
                .animation(.spring(response: 0.22, dampingFraction: 0.72), value: currentStep)
            }

            // Foreground tempo diagram asset
            Image("Guidebook_Tempo")
                .resizable()
                .scaledToFit()
                .frame(width: diagramWidth, height: diagramHeight)
                .allowsHitTesting(false)
        }
        .frame(width: diagramWidth, height: diagramHeight)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview("Tempo Controls Only") {
    GuidebookTempoControlView(
        viewModel: GuidebookViewModel(onBackRequested: {})
    )
    .padding()
    .background(Color(red: 0.96, green: 0.90, blue: 0.80))
}

#Preview("In Context (On Guidebook 2 Card)") {
    ZStack(alignment: .top) {
        Image("Guidebook_2")
            .resizable()
            .scaledToFit()
            .frame(width: 685, height: 805)

        GuidebookTempoControlView(
            viewModel: GuidebookViewModel(onBackRequested: {})
        )
        .padding(.top, 130)
    }
    .frame(width: 685, height: 805)
    .padding()
    .background(AppColors.brownPrimary.opacity(0.85))
}

