import Foundation

/// Names of the Showtime images in the asset catalog. They are written exactly as the files were
/// named by design, so check the spelling and capital letters against the catalog.
enum ShowtimeAssets {
    static let background = "Showtime_BG Hifi"
    static let floor = "Showtime_Floor"
    static let titleBox = "Showtime_Title Box"
    static let vinyl = "Showtime_vynil"
    static let woodWall = "Showtime_Wood wall"
    static let recordBox = "Showtime_Record box"

    /// "Showtime_0 star" ... "Showtime_3 star".
    static func star(_ count: Int) -> String {
        "Showtime_\(min(max(count, 0), 3)) star"
    }

    static func character(forSongID id: String) -> String {
        switch id {
        case "abc-song": "cat_abc song"
        case "down-by-the-riverside": "Cat_Down to the river"
        case "jingle-bells": "cat_jingle bells"
        case "row-row-row-your-boat": "cat_row your boat"
        default: "Cat_twinkle twinkle"
        }
    }

    static func audioResource(forSongID id: String) -> String? {
        switch id {
        case "abc-song": "3_syncopation_abc_song"
        case "down-by-the-riverside": "5_driving_pop_down_by_the_riverside"
        case "jingle-bells": "2_subdivision_jingle_bells"
        case "row-row-row-your-boat": "4_upbeat_row_row_row_your_boat"
        case "twinkle-twinkle": "1_foundation_twinkle_twinkle"
        default: nil
        }
    }

    static func patternArtwork(forPatternID id: String) -> String? {
        switch id {
        case "foundation": "Showtime_foundation pattern"
        case "subdivision": "Showtime_subdivison pattern"
        case "syncopation": "showtime_snycopation pattern"
        case "upbeat": "Showtime_the upbeat pattern"
        case "dynamic", "driving-pop", "drivingpop": "showtime_driving pop pattern"
        default: nil
        }
    }
}
