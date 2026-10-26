import CoreText
import Foundation

enum AppFontRegistrar {
    static func registerFonts() {
        registerFont(named: "Bungee-Regular", extension: "ttf")
        registerFont(named: "DMMono-Medium", extension: "ttf")
    }

    private static func registerFont(named name: String, extension fileExtension: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            assertionFailure("Missing bundled font: \(name).\(fileExtension)")
            return
        }

        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
