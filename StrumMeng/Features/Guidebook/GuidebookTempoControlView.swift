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
            // 8-beat strum diagram asset: 1 & 2 & 3 & 4 & with [↓] [↑] arrows
            Image("Guidebook_Tempo")
                .resizable()
                .scaledToFit()
                .frame(width: 530)
                .frame(maxWidth: .infinity, alignment: .center)
                
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

