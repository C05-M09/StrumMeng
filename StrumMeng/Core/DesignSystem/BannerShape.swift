import SwiftUI

/// Wider at the top than at the bottom, with well-rounded bottom corners (never a sharp angle).
/// The top edge sits flush with the screen.
struct BannerShape: Shape {
    /// Horizontal slant of each side, as a fraction of the width.
    var inset: CGFloat = 0.085
    /// Bottom corner radius, as a fraction of the height.
    var cornerRadius: CGFloat = 0.24

    func path(in rect: CGRect) -> Path {
        let slant = rect.width * inset
        let radius = rect.height * cornerRadius
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX - slant, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.addArc(tangent1End: CGPoint(x: rect.minX + slant, y: rect.maxY),
                    tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: radius)
        path.closeSubpath()
        return path
    }
}
