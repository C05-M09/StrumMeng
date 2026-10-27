import Foundation

enum PatternCatalog {
    static let all: [StrumPattern] = [
        StrumPattern(
            id: "foundation",
            name: "Foundation Strum",
            strokes: [.down, .rest, .down, .rest, .down, .rest, .down, .rest],
            beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
            beatsPerPattern: 4,
            suggestedOrder: 1,
            defaultBPM: 80
        ),
        StrumPattern(
            id: "subdivision",
            name: "Subdivision Strum",
            strokes: [.down, .up, .down, .up, .down, .up, .down, .up],
            beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
            beatsPerPattern: 4,
            suggestedOrder: 2,
            defaultBPM: 80
        ),
        StrumPattern(
            id: "syncopation",
            name: "Syncopation Strum",
            strokes: [.down, .rest, .down, .up, .rest, .up, .down, .up],
            beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
            beatsPerPattern: 4,
            suggestedOrder: 3,
            defaultBPM: 80
        ),
        StrumPattern(
            id: "upbeat",
            name: "The Upbeat Strum",
            strokes: [.down, .rest, .rest, .up, .down, .rest, .rest, .up],
            beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
            beatsPerPattern: 4,
            suggestedOrder: 4,
            defaultBPM: 80
        ),
        StrumPattern(
            id: "dynamic",
            name: "Dynamic Strum",
            strokes: [.down, .rest, .down, .rest, .down, .rest, .down, .rest],
            beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
            beatsPerPattern: 4,
            suggestedOrder: 5,
            defaultBPM: 80
        ),
    ]

    /// Lookup a pattern by its stable id slug.
    static func pattern(forID id: String) -> StrumPattern? {
        all.first { $0.id == id }
    }

    static var foundation: StrumPattern { all[0] }
    static var subdivision: StrumPattern { all[1] }
    static var syncopation: StrumPattern { all[2] }
    static var theUpbeat: StrumPattern { all[3] }
    static var dynamic: StrumPattern { all[4] }
}
