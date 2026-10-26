import SwiftUI

struct AssetButtonStyle: ButtonStyle {
    let normalAssetName: String
    let pressedAssetName: String
    let size: CGSize

    func makeBody(configuration: Configuration) -> some View {
        Image(configuration.isPressed ? pressedAssetName : normalAssetName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
    }
}
