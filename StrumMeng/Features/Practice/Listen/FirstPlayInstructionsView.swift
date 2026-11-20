import SwiftUI

// Pengaturan tampilan modal: ubah angka di sini sambil melihat Canvas.
enum FirstPlayInstructionsLayout {
    static let artworkAssetName = "2_Guidance"
    // Besarkan/kecilkan gambar modal; tombol Next tetap memakai ukuran nextSize.
    static let modalScale: CGFloat = 1.15
    static let panelSize = CGSize(width: 1080 * modalScale, height: 800 * modalScale)
    static let panelCenter = CGPoint(x: 688, y: 516)
    static let nextSize = CGSize(width: 210, height: 94)
    // Nilai lebih kecil menggeser tombol ke kanan / ke bawah.
    static let nextTrailingInset: CGFloat = 8
    static let nextBottomInset: CGFloat = 12
    static let scrimOpacity = 0.78
}

/// Designer guidance artwork with a separate interactive Next button.
struct FirstPlayInstructionsView: View {
    let onNext: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    var body: some View {
        ZStack {
            AppColors.brownInk.opacity(FirstPlayInstructionsLayout.scrimOpacity)
            ZStack {
                Image(FirstPlayInstructionsLayout.artworkAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: FirstPlayInstructionsLayout.panelSize.width,
                           height: FirstPlayInstructionsLayout.panelSize.height)
                    .accessibilityLabel("Rotate your phone and strum in the zone. Strum as the arrow hits the circle. Green is perfect. Yellow is early. Red is a miss.")
                    .overlay(alignment: .bottomTrailing) {
                        Button("Next", action: onNext)
                            .buttonStyle(AssetButtonStyle(normalAssetName: "Button_Next_Normal",
                                pressedAssetName: "Button_Next_Pressed", size: FirstPlayInstructionsLayout.nextSize))
                            .padding(.trailing, FirstPlayInstructionsLayout.nextTrailingInset)
                            .padding(.bottom, FirstPlayInstructionsLayout.nextBottomInset)
                    }
                    .position(FirstPlayInstructionsLayout.panelCenter)
            }
            .scaleEffect(visible || reduceMotion ? 1 : 0.96)
            .opacity(visible ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: visible)
        }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
        .accessibilityAddTraits(.isModal)
        .onAppear { visible = true }
    }

}

#Preview("First Play positioning and feedback", traits: .landscapeLeft) {
    Image("Play_BG").resizable().overlay { FirstPlayInstructionsView(onNext: {}) }
        .frame(width: AppLayout.referenceSize.width, height: AppLayout.referenceSize.height)
}
