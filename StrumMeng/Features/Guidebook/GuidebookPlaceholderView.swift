import SwiftUI

/// Stand-in until the Guidebook screen (US 5) is built, so the Guidebook icon on Home is not a dead end.
/// Replace it with the real screen and delete this file.
struct GuidebookPlaceholderView: View {
    let onBack: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let scale = max(
                proxy.size.width / AppLayout.referenceSize.width,
                proxy.size.height / AppLayout.referenceSize.height
            )

            ZStack {
                AppColors.brownPrimary
                    .ignoresSafeArea()
                    .opacity(0.8)

                ZStack {
                    Text("GUIDEBOOK")
                        .font(AppTypography.bungee(size: 70))
                        .foregroundStyle(AppColors.cream)

                    BackButton(action: onBack)
                        .position(BackButton.referenceCenter)
                }
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
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    GuidebookPlaceholderView(onBack: {})
}
