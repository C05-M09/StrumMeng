import CoreGraphics

enum FirstPlayInstructionsLayout {
    /// Set this to the designer's imageset name when the final full-modal artwork is available.
    /// Next remains a separate interactive button, outside the artwork.
    static let artworkAssetName: String? = nil
    static let panelSize = CGSize(width: 1080, height: 800)
    static let panelCenter = CGPoint(x: 688, y: 516)
    static let contentWidth: CGFloat = 880
    static let contentCenter = CGPoint(x: 688, y: 465)
    static let titleSize: CGFloat = 42
    static let bodySize: CGFloat = 26
    static let legendSize: CGFloat = 24
    static let sectionSpacing: CGFloat = 28
    static let rowSpacing: CGFloat = 18
    static let rowHeight: CGFloat = 50
    static let dotSize: CGFloat = 30
    static let nextSize = CGSize(width: 252, height: 112)
    static let nextCenter = CGPoint(x: 1070, y: 830)
    static let scrimOpacity = 0.78
}
