import Foundation

/// Stars of a Showtime record, from its accuracy in percent (0...100).
/// 0-50 -> 0 stars, 51-65 -> 1, 66-85 -> 2, 86-100 -> 3.
/// A decimal accuracy is rounded to a whole percent first, so 50.4 counts as 50.
nonisolated enum ShowtimeStars {
    static func count(forAccuracyPercent accuracy: Double) -> Int {
        switch Int(accuracy.rounded()) {
        case ...50: 0
        case 51...65: 1
        case 66...85: 2
        default: 3
        }
    }
}
