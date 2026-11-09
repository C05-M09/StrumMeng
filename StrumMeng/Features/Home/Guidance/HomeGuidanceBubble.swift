import SwiftUI

/// Filled body and right-hand pointer share one shadow, with no stroked join.
struct HomeGuidanceBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX, y: rect.minY,
                          width: rect.width - HomeGuidanceLayout.pointerLength,
                          height: rect.height)
        var path = Path(roundedRect: body, cornerRadius: HomeGuidanceLayout.cornerRadius)
        let half = HomeGuidanceLayout.pointerHalfWidth
        path.move(to: CGPoint(x: body.maxX, y: rect.midY - half))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: body.maxX, y: rect.midY + half))
        path.closeSubpath()
        return path
    }
}
