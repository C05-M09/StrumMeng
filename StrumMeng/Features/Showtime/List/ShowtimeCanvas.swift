import SwiftUI

/// Colors and fonts shared by the Showtime screens. Swap the fonts for the app's own.
enum ShowtimeStyle {
    static let cream = Color(red: 0.97, green: 0.91, blue: 0.78)
    static let orange = Color(red: 0.93, green: 0.55, blue: 0.13)
    static let darkBrown = Color(red: 0.29, green: 0.15, blue: 0.07)
    static let downRed = Color(red: 0.80, green: 0.17, blue: 0.17)
    static let upTeal = Color(red: 0.30, green: 0.55, blue: 0.52)

    static func font(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func title(_ size: CGFloat) -> Font {
        AppTypography.bungee(size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        AppTypography.dmMono(size: size)
    }
}

/// Lays children out in `AppLayout.referenceSize` points (use `.position` / `.offset` inside) and
/// scales the whole canvas to fit the screen, like the other screens.
struct ShowtimeCanvas<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let reference = AppLayout.referenceSize
            let scale = min(geometry.size.width / reference.width,
                            geometry.size.height / reference.height)
            content
                .frame(width: reference.width, height: reference.height)
                .clipped()
                .scaleEffect(scale)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}
