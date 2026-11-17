import Foundation

/// Metadata for one of the three Showtime strumming patterns of a song.
struct ShowtimePatternInfo: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let assetName: String
    let strokes: [Stroke]
    let beatsPerPattern: Int

    var strumPattern: StrumPattern {
        StrumPattern(
            id: id,
            name: name,
            strokes: strokes,
            beatLabels: ["1", "&", "2", "&", "3", "&", "4", "&"],
            beatsPerPattern: beatsPerPattern,
            suggestedOrder: 1,
            defaultBPM: 100
        )
    }
}

/// Catalog of the 3 Showtime patterns for each of the 5 songs, matching the assets in Assets.xcassets/Songs.
enum ShowtimePatternCatalog {
    static let songPatterns: [String: [ShowtimePatternInfo]] = [
        "twinkle-twinkle": [
            ShowtimePatternInfo(
                id: "half-time-hold",
                name: "Half-Time Hold Strum",
                assetName: "Twinkle_Half Time Hold",
                strokes: [.down, .rest, .rest, .rest, .down, .rest, .rest, .rest],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "foundation",
                name: "Foundation Strum",
                assetName: "Twinkle_Foundation",
                strokes: [.down, .rest, .down, .rest, .down, .rest, .down, .rest],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "lullaby-sway",
                name: "Lullaby Sway Strum",
                assetName: "Twinkle_Lullaby Sway",
                strokes: [.down, .rest, .down, .rest, .down, .up, .rest, .rest],
                beatsPerPattern: 4
            )
        ],
        "jingle-bells": [
            ShowtimePatternInfo(
                id: "sleigh-trot",
                name: "Sleigh Trot Strum",
                assetName: "Jingle Bells_Sleigh Trot",
                strokes: [.down, .rest, .up, .rest, .down, .rest, .up, .rest],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "subdivision",
                name: "Subdivision Strum",
                assetName: "Jingle Bells_Subdivision",
                strokes: [.down, .up, .down, .up, .down, .up, .down, .up],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "sleigh-gallop",
                name: "Sleigh Gallop Strum",
                assetName: "Jingle Bells_Sleigh Gallop",
                strokes: [.down, .rest, .down, .up, .down, .rest, .down, .up],
                beatsPerPattern: 4
            )
        ],
        "abc-song": [
            ShowtimePatternInfo(
                id: "steady-lift",
                name: "Steady Lift Strum",
                assetName: "ABC_Steady Lift",
                strokes: [.down, .rest, .down, .rest, .down, .rest, .down, .up],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "syncopation",
                name: "Syncopation Strum",
                assetName: "ABC_Syncopation",
                strokes: [.down, .rest, .down, .up, .rest, .up, .down, .up],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "rolling-skip",
                name: "Rolling Skip Strum",
                assetName: "ABC_Rolling Skip",
                strokes: [.down, .rest, .down, .up, .down, .up, .down, .rest],
                beatsPerPattern: 4
            )
        ],
        "row-row-row-your-boat": [
            ShowtimePatternInfo(
                id: "paddle-stroke",
                name: "Paddle Stroke Strum",
                assetName: "Row Your Boat_Paddle Stroke",
                strokes: [.down, .rest, .up, .rest, .down, .rest, .rest, .up],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "upbeat",
                name: "The Upbeat Strum",
                assetName: "Row Your Boat_The Upbeat",
                strokes: [.down, .rest, .rest, .up, .down, .rest, .rest, .up],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "boat-rock",
                name: "Boat Rock Strum",
                assetName: "Row Your Boat_Boat Rock",
                strokes: [.down, .rest, .rest, .up, .down, .rest, .down, .rest],
                beatsPerPattern: 4
            )
        ],
        "down-by-the-riverside": [
            ShowtimePatternInfo(
                id: "spiritual-swing",
                name: "Spiritual Swing Strum",
                assetName: "Down by The River_Spiritual Swing",
                strokes: [.down, .rest, .rest, .up, .down, .rest, .down, .up],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "driving",
                name: "Driving Pop Strum",
                assetName: "Down by The River_Driving Pop",
                strokes: [.down, .rest, .down, .up, .down, .rest, .down, .rest],
                beatsPerPattern: 4
            ),
            ShowtimePatternInfo(
                id: "gospel-stomp",
                name: "Gospel Stomp Strum",
                assetName: "Down by The River_Gospel Stomp",
                strokes: [.down, .rest, .down, .rest, .down, .up, .down, .rest],
                beatsPerPattern: 4
            )
        ]
    ]

    static func patterns(forSongID id: String) -> [ShowtimePatternInfo] {
        songPatterns[id] ?? []
    }

    static func defaultPatternID(for songID: String) -> String {
        songPatterns[songID]?.first?.id ?? "foundation"
    }

    static func patternInfo(forID id: String) -> ShowtimePatternInfo? {
        for list in songPatterns.values {
            if let found = list.first(where: { $0.id == id }) {
                return found
            }
        }
        return nil
    }

    static func pattern(forID id: String) -> StrumPattern? {
        patternInfo(forID: id)?.strumPattern
    }

    static func songID(forPatternID patternID: String) -> String? {
        for (songID, patterns) in songPatterns {
            if patterns.contains(where: { $0.id == patternID }) {
                return songID
            }
        }
        return nil
    }
}

