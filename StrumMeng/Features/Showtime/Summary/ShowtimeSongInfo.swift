//
//  ShowtimeSongInfo.swift
//  StrumMeng
//
//  Created by Sharon Tan on 12/11/26.
//

import Foundation

/// Display metadata for the song shown on the Showtime Summary song card.
struct ShowtimeSongInfo: Equatable, Sendable {
    let title: String
    let durationLabel: String
    let chords: [String]

    /// Formatted chords string for display on the summary card.
    var chordsLabel: String {
        chords.isEmpty ? "-" : chords.joined(separator: "  ")
    }

    /// Fallback metadata derived from `SessionResult` when no song catalog entry is wired yet.
    static func fallback(for result: SessionResult) -> ShowtimeSongInfo {
        let formattedTitle = result.songID?
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized ?? "Showtime Song"

        return ShowtimeSongInfo(
            title: formattedTitle,
            durationLabel: "1 min 30 sec",
            chords: ["C", "G", "Am", "F"]
        )
    }
}

// In an extension so the memberwise initialiser stays available.
extension ShowtimeSongInfo {
    /// The played song's title, chart length and chords in order of first appearance.
    init(song: Song) {
        self.init(title: song.title,
                  durationLabel: PracticeSessionConfig.durationLabel(seconds: song.durationSeconds),
                  chords: song.distinctChords)
    }
}
