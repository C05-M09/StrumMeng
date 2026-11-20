import SwiftUI

/// Colour tokens. The only place a raw colour may be written.
/// Practice-Play values are the designer's hex codes; the rest are sampled from the hi-fi exports
/// until their codes are handed over. Contrast is checked per CLAUDE.md §15.
enum AppColor {
    // Screen and header
    static let practiceBackground = Color(hex: 0xD1B48B)   // tan screen background
    static let bannerBrown = Color(hex: 0x5E301E)          // hanging header box
    static let titleText = Color(hex: 0xFFF6DE)            // header title
    static let ink = Color(hex: 0x2E170E)                  // outlines and dark text

    // Practice board
    static let boardRed = Color(hex: 0xCD3630)             // outer red layer
    static let paper = Color(hex: 0xF4E3C2)                // cream inside the red layer, node rings, modal
    static let laneBorderTeal = Color(hex: 0x297066)       // green layer around the game lane
    static let laneBackground = Color(hex: 0x2E170E)       // dark brown inside the game
    static let track = Color(hex: 0xE99C3E)                // orange rail the nodes travel on
    static let laneLabel = Color(hex: 0xFFFFFF)            // 1 & 2 & labels under the nodes
    static let progressTrack = Color(hex: 0xD1B48B)
    static let progressStroke = Color(hex: 0x8B6B4A)
    static let progressFill = Color(hex: 0xFFFFFF)

    // Feedback on the hit ring (colour only, CLAUDE.md §9)
    static let perfect = Color(hex: 0x6BD14F)
    static let tooEarly = Color(hex: 0xE8B931)
    static let miss = Color(hex: 0xE04A3C)

    // Controls and overlays
    static let buttonPrimary = Color(hex: 0xE3A04F)        // orange
    static let buttonSecondary = Color(hex: 0xCDB590)      // tan
    static let buttonDanger = Color(hex: 0xC9483B)         // red pause / back
    static let calloutText = Color(hex: 0xFFFFFF)          // READY? and count-in numbers over the veil
    static let dim = Color(hex: 0x3A1C0E)                  // brown veil behind READY?, count-in and pause
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
