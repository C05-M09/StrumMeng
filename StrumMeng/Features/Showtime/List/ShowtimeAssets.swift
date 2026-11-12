import Foundation

/// Names of the Showtime images in the asset catalog. They are written exactly as the files were
/// named by design, so check the spelling and capital letters against the catalog.
enum ShowtimeAssets {
    private static let namespace = "Showtime_Assets/"

    static let background = "Showtime_BG Hifi"
    static let floor = namespace + "Showtime_Floor"
    static let titleBox = namespace + "Showtime_Title Box"
    static let vinyl = namespace + "Showtime_vynil"
    static let woodWall = namespace + "Showtime_Wood wall"
    static let recordBox = namespace + "Showtime_Record box"

    /// "Showtime_0 star" ... "Showtime_3 star".
    static func star(_ count: Int) -> String {
        namespace + "Showtime_\(min(max(count, 0), 3)) star"
    }

    static func character(forSongID id: String) -> String {
        let name: String
        switch id {
        case "abc-song": name = "cat_abc song"
        case "down-by-the-riverside": name = "Cat_Down to the river"
        case "jingle-bells": name = "cat_jingle bells"
        case "row-row-row-your-boat": name = "cat_row your boat"
        default: name = "Cat_twinkle twinkle"
        }
        return namespace + name
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
        let name: String
        switch id {
        case "foundation": name = "Showtime_foundation pattern"
        case "subdivision": name = "Showtime_subdivison pattern"
        case "syncopation": name = "showtime_snycopation pattern"
        case "upbeat": name = "Showtime_the upbeat pattern"
        case "dynamic", "driving", "driving-pop", "drivingpop": name = "showtime_driving pop pattern"
        default: return nil
        }
        return namespace + name
    }
}
