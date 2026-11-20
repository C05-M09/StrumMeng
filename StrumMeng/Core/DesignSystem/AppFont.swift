import CoreText
import SwiftUI

/// Font tokens. Bungee for titles and buttons, DM Mono for numbers (BPM, time, counts).
/// The fonts are registered at runtime on first use, so they also work in Xcode previews
/// without an Info.plist UIAppFonts entry.
enum AppFont {
    private static let bungee = "Bungee-Regular"
    private static let dmMono = "DMMono-Medium"

    private static let registration: Void = {
        for name in [bungee, dmMono] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    /// Level titles, banners, big count-in numbers.
    static func display(_ size: CGFloat) -> Font {
        _ = registration
        return .custom(bungee, fixedSize: size)
    }

    /// BPM, session time, counts and labels.
    static func mono(_ size: CGFloat) -> Font {
        _ = registration
        return .custom(dmMono, fixedSize: size)
    }
}
