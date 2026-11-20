import CoreGraphics

/// Reference-canvas geometry shared with the Listen-style welcome illustration.
enum PairingIntroductionLayout {
    static let bannerSize = CGSize(width: 1500, height: 616)
    static let bannerCenter = CGPoint(x: 688, y: 516)
    static let characterSize = CGSize(width: 960, height: 1020)
    static let characterCenter = CGPoint(x: 450, y: 620)
    static let bubbleSize = CGSize(width: 850, height: 320)
    static let bubbleCenter = CGPoint(x: 895, y: 680)
    static let textWidth: CGFloat = 700
    static let textOffset = CGSize(width: 30, height: -10)
    static let nextSize = CGSize(width: 252, height: 112)
    static let nextCenter = CGPoint(x: 1190, y: 825)
    static let scrimOpacity = 0.9
    static let copySpacing: CGFloat = 8
    static let copyFontSize: CGFloat = 28
    static let hintFontSize: CGFloat = 18
}
