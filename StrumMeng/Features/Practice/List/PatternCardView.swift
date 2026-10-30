import SwiftUI

struct PatternCardView: View {
    let pattern: StrumPattern
    let bpm: Int
    let onDecreaseBPM: () -> Void
    let onIncreaseBPM: () -> Void
    var recordsViewModel: RecordsViewModel? = nil
    var recordsFallbackState: RecordsViewState = .empty

    var body: some View {
        ZStack {
            Image(cardAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 662.03, height: 742.38)

            Button(action: onDecreaseBPM) {
                Color.clear
            }
            .buttonStyle(
                AssetButtonStyle(
                    normalAssetName: "Button_Minus_Normal",
                    pressedAssetName: "Button_Minus_Pressed",
                    size: CGSize(width: 40.59, height: 43.68)
                )
            )
            .disabled(bpm <= PracticeTempoConfig.minimumBPM)
            .opacity(bpm <= PracticeTempoConfig.minimumBPM ? 0.55 : 1)
            .position(x: 171, y: 220)
            .accessibilityLabel("Decrease BPM")
            .accessibilityHint("Decreases the tempo by 5 BPM")

            Text(String(bpm))
                .font(AppTypography.dmMono(size: 30))
                .foregroundStyle(AppColors.brownInk)
                .monospacedDigit()
                .frame(width: 66.85, height: 45.1)
                .position(x: 233.62, y: 220.03)
                .accessibilityLabel("Tempo \(bpm) BPM")

            Button(action: onIncreaseBPM) {
                Color.clear
            }
            .buttonStyle(
                AssetButtonStyle(
                    normalAssetName: "Button_Plus_Normal",
                    pressedAssetName: "Button_Plus_Pressed",
                    size: CGSize(width: 40.59, height: 43.68)
                )
            )
            .disabled(bpm >= PracticeTempoConfig.maximumBPM)
            .opacity(bpm >= PracticeTempoConfig.maximumBPM ? 0.55 : 1)
            .position(x: 296, y: 220)
            .accessibilityLabel("Increase BPM")
            .accessibilityHint("Increases the tempo by 5 BPM")

            Text(sessionDurationLabel)
            .font(AppTypography.dmMono(size: 20))
            .foregroundStyle(AppColors.brownInk)
            .monospacedDigit()
            .position(x: 555, y: 220)
            .accessibilityLabel("Session duration \(sessionDurationLabel)")

            Group {
                if let recordsViewModel {
                    RecordsView(viewModel: recordsViewModel)
                } else {
                    RecordsContentView(state: recordsFallbackState)
                }
            }
            .frame(width: 570)
            .position(x: 331, y: 478)
        }
        .frame(width: 662.03, height: 742.38)
    }

    private var cardAssetName: String {
        switch pattern.id {
        case "foundation":
            "Practice_Foundation Strum"
        case "subdivision":
            "Practice_Subdivision Strum"
        case "syncopation":
            "Practice_Syncopation Strum"
        case "upbeat":
            "Practice_Upbeat Strum"
        case "dynamic":
            "Practice_Dynamic Strum"
        default:
            "Practice_Foundation Strum"
        }
    }

    private var sessionDurationLabel: String {
        PracticeSessionConfig.durationLabel(for: pattern, bpm: bpm)
    }
}

#Preview {
    PatternCardView(
        pattern: PatternCatalog.all[1],
        bpm: 80,
        onDecreaseBPM: {},
        onIncreaseBPM: {}
    )
    .background(AppColors.brownPrimary)
}
