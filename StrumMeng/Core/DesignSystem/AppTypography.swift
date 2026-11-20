import SwiftUI

enum AppTypography {
    static func bungee(size: CGFloat) -> Font {
        .custom("Bungee-Regular", size: size)
    }

    static func dmMono(size: CGFloat) -> Font {
        .custom("DMMono-Medium", size: size)
    }
}
