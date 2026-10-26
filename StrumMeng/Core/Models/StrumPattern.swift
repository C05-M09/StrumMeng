import Foundation

struct StrumPattern: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let name: String
    let strokes: [Stroke]
    let beatLabels: [String]
    let beatsPerPattern: Int
    let suggestedOrder: Int
    let defaultBPM: Int
}
