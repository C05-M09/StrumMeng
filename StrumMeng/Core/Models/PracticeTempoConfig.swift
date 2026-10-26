import Foundation

enum PracticeTempoConfig {
    static let minimumBPM = 60
    static let maximumBPM = 120
    static let step = 5

    static func clamped(_ bpm: Int) -> Int {
        min(max(bpm, minimumBPM), maximumBPM)
    }
}
