import SwiftUI

/// Sizes for the Option card, in the app's reference space (`AppLayout.referenceSize`, 1376 x 1032).
enum OptionCardLayout {
    /// Size the full `Option_Card` artwork is drawn at, before it is shortened.
    static let artSize = CGSize(width: 890, height: 685)

    /// How much shorter / narrower the card is than the artwork. Bigger = flatter.
    /// The cut is a blank band taken out of the artwork, so it must not touch the rows or the title.
    static let heightReduction: CGFloat = 140
    static let widthReduction: CGFloat = 0

    /// Where the blank band starts in the artwork (from its top / left edge).
    static let heightCutStart: CGFloat = 500
    static let widthCutStart: CGFloat = 120

    /// The size the card ends up with.
    static var size: CGSize {
        CGSize(
            width: artSize.width - widthReduction,
            height: artSize.height - heightReduction
        )
    }

    /// Set to false if the `Option_Card` artwork already draws the "OPTION" title.
    static let drawsTitle = true
    static let titleFontSize: CGFloat = 50
    static let titleTopPadding: CGFloat = 86

    /// Distance from the top of the card to the first row (icon and label).
    static let rowsTopInset: CGFloat = 190

    static let rowSpacing: CGFloat = 56
    static let iconSize: CGFloat = 90
    static let iconColumnWidth: CGFloat = 130
    static let iconToSliderSpacing: CGFloat = 40
    static let sliderWidth: CGFloat = 386
    static let labelFontSize: CGFloat = 40
}
