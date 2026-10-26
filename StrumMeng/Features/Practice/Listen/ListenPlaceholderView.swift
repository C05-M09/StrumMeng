import SwiftUI

struct ListenPlaceholderView: View {
    let pattern: StrumPattern
    let bpm: Int
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Image("Practice_BG")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("LISTEN")
                    .font(AppTypography.bungee(size: 70))
                    .foregroundStyle(AppColors.white)

                Text(pattern.name)
                    .font(AppTypography.bungee(size: 40))
                    .foregroundStyle(AppColors.cream)

                Text("\(bpm) BPM")
                    .font(AppTypography.dmMono(size: 30))
                    .foregroundStyle(AppColors.cream)

                Button("Back", action: onBack)
                    .font(AppTypography.dmMono(size: 20))
                    .foregroundStyle(AppColors.brownInk)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppColors.yellowAccent, in: Capsule())
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    ListenPlaceholderView(
        pattern: PatternCatalog.all[0],
        bpm: 80,
        onBack: {}
    )
}
