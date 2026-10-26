import Foundation

/// Static catalog of the five core strumming patterns.
///
/// All patterns are open from the start; `suggestedOrder` indicates the recommended progression.
enum PatternCatalog {
    static let foundation = StrumPattern(
        id: "foundation",
        name: "Foundation",
        strokes: [.down, .rest, .down, .rest, .down, .rest, .down, .rest],
        beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
        suggestedOrder: 1,
        defaultBPM: 60
    )

    static let subdivision = StrumPattern(
        id: "subdivision",
        name: "Subdivision",
        strokes: [.down, .rest, .down, .up, .down, .rest, .down, .up],
        beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
        suggestedOrder: 2,
        defaultBPM: 70
    )

    static let syncopation = StrumPattern(
        id: "syncopation",
        name: "Syncopation",
        strokes: [.down, .rest, .rest, .up, .rest, .up, .down, .rest],
        beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
        suggestedOrder: 3,
        defaultBPM: 80
    )

    static let theUpbeat = StrumPattern(
        id: "the-upbeat",
        name: "The Upbeat",
        strokes: [.rest, .up, .rest, .up, .rest, .up, .rest, .up],
        beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
        suggestedOrder: 4,
        defaultBPM: 80
    )

    static let dynamic = StrumPattern(
        id: "dynamic",
        name: "Dynamic",
        strokes: [.down, .down, .down, .up, .down, .rest, .down, .up],
        beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
        suggestedOrder: 5,
        defaultBPM: 90
    )

    /// All five patterns sorted by their suggested order.
    static let all: [StrumPattern] = [
        foundation,
        subdivision,
        syncopation,
        theUpbeat,
        dynamic
    ]

    /// Lookup a pattern by its stable id slug.
    static func pattern(forID id: String) -> StrumPattern? {
        all.first { $0.id == id }
    }
}
