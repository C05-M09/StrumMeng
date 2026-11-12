import SwiftUI

struct ShowtimeFinishedView: View {
    let title: String
    let result: SessionResult
    let onRestart: () -> Void
    let onBack: () -> Void
    var body: some View {
        ZStack {
            Image("Showtime_Assets/Showtime_BG").resizable()
            Image("Option_Card").resizable().scaledToFit().frame(width: 1000, height: 800)
            VStack(spacing: AppSpacing.l) {
                Text("SESSION COMPLETE").font(AppTypography.bungee(size: 48))
                Text(title).font(AppTypography.dmMono(size: 28))
                Text("\(Int((result.accuracy * 100).rounded()))% Accuracy")
                    .font(AppTypography.bungee(size: 44))
                Text("Perfect \(result.perfectCount) • Too Early \(result.tooEarlyCount) • Miss \(result.missCount)")
                    .font(AppTypography.dmMono(size: 24))
                Button("Restart", action: onRestart)
                    .buttonStyle(AssetButtonStyle(normalAssetName: "Button_Restart_Normal",
                        pressedAssetName: "Button_Restart_Pressed", size: CGSize(width: 510, height: 88)))
                Button("Back to Menu", action: onBack)
                    .buttonStyle(AssetButtonStyle(normalAssetName: "Button_Back to Menu_Normal",
                        pressedAssetName: "Button_Back to Menu_Pressed", size: CGSize(width: 510, height: 88)))
            }.foregroundStyle(AppColors.brownInk)
        }
    }
}
