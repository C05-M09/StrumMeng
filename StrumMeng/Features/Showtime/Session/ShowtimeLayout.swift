import CoreGraphics

/// Reference-space values shared by Listen and the introduction.
enum ShowtimeLayout {
    static let size = CGSize(width: 1376, height: 1032)
    static let node: CGFloat = 114
    static let ring: CGFloat = 132
    static let firstX: CGFloat = 194
    static let slot: CGFloat = 142
    static let railY: CGFloat = 548
    static let chordY: CGFloat = 416
    static let countY: CGFloat = 666
    static let titleLineSpacing: CGFloat = -12
    static let titleSize: CGFloat = 52
    static let monoSize: CGFloat = 32
    static let patternSelectorCenter = CGPoint(x: 280, y: 884)
    static let readyCenter = CGPoint(x: 1140, y: 884)
    static let readySize = CGSize(width: 294, height: 116)
    static let scrimOpacity = 0.78
    static let frameInterval = 1.0 / 60
    // Match the current Practice Listen information composition (ListenView.swift).
    static let informationBannerSize = CGSize(width: 1500, height: 616)
    static let informationBannerCenter = CGPoint(x: 688, y: 516)
    static let informationCharacterSize = CGSize(width: 920, height: 1000)
    static let informationCharacterCenter = CGPoint(x: 450, y: 567)
    static let informationBubbleSize = CGSize(width: 850, height: 320)
    static let informationBubbleCenter = CGPoint(x: 895, y: 680)
    static let informationTextCenter = CGPoint(x: 925, y: 675)
    static let informationTextWidth: CGFloat = 720
    static let informationNextCenter = CGPoint(x: 1190, y: 825)
    static let informationScrimOpacity = 0.9
}
