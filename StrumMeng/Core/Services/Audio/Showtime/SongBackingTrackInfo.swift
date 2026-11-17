import Foundation

/// Where a song's recording lives and where its first beat is, so that beat lands on node 1.
nonisolated struct SongBackingTrackInfo: Sendable, Equatable {
    /// mp3 name in the app bundle, without the extension.
    let resource: String
    /// Seconds into the file where bar 1 starts: the first node lands here.
    let firstBeat: TimeInterval
    var loop: SongLoopConfiguration? = nil
    /// The recording is much longer than the chart, so it fades out over the last bar and stops
    /// on the last node instead of playing on after the gameplay ends. Not for a looped song.
    var fadesOutAtChartEnd = false

    struct Segment: Sendable, Equatable {
        let filePosition: TimeInterval
        let duration: TimeInterval
        let hostTime: TimeInterval
    }

    /// Pre-schedule all remaining loops on audio time, including a resume in the middle of a loop.
    /// Only the final repetition keeps the file's natural decay; earlier loops end on the bar line.
    func segments(fromSongTime songTime: TimeInterval, atHostTime hostTime: TimeInterval,
                  fileDuration: TimeInterval) -> [Segment] {
        guard let loop else {
            let point = start(fromSongTime: songTime, atHostTime: hostTime)
            guard point.filePosition < fileDuration else { return [] }
            return [Segment(filePosition: point.filePosition,
                            duration: fileDuration - point.filePosition, hostTime: point.hostTime)]
        }
        guard songTime < loop.durationPerLoop * Double(loop.count) else { return [] }
        let firstLoop = max(0, Int(floor(songTime / loop.durationPerLoop)))
        return (firstLoop..<loop.count).compactMap { index in
            let loopStart = Double(index) * loop.durationPerLoop
            let position = index == firstLoop ? songTime - loopStart : 0
            let time = index == firstLoop ? hostTime : hostTime + loopStart - songTime
            let point = start(fromSongTime: position, atHostTime: time)
            let end = index == loop.count - 1 ? fileDuration : min(fileDuration, firstBeat + loop.durationPerLoop)
            guard end > point.filePosition else { return nil }
            return Segment(filePosition: point.filePosition, duration: end - point.filePosition,
                           hostTime: point.hostTime)
        }
    }

    /// The bundled recordings, measured with a beat-grid fit of each file (2026-11-12: 100, 120,
    /// 100, 110 and 100 BPM; Twinkle is the re-recorded file of PR #62). Four start on bar 1 at the top of the file; Riverside opens with
    /// silence and three sixteenth pickups (from 1.93 s) into bar 1 at 2.38 s.
    static let all: [String: SongBackingTrackInfo] = [
        "twinkle-twinkle": .init(resource: "1_foundation_twinkle_twinkle", firstBeat: 0),
        "jingle-bells": .init(resource: "2_subdivision_jingle_bells", firstBeat: 0),
        "abc-song": .init(resource: "3_syncopation_abc_song", firstBeat: 0),
        "row-row-row-your-boat": .init(resource: "4_upbeat_row_row_row_your_boat", firstBeat: 0, loop: .rowBoat),
        // 157 s of recording for a 16-bar (38 s) chart.
        "down-by-the-riverside": .init(resource: "5_driving_pop_down_by_the_riverside", firstBeat: 2.38,
                                       fadesOutAtChartEnd: true),
    ]

    /// Seconds into the file at a session time.
    func filePosition(atSongTime songTime: TimeInterval) -> TimeInterval {
        firstBeat + songTime
    }

    static func forSong(_ songID: String) -> SongBackingTrackInfo? {
        all[songID]
    }

    /// Where to start in the file and when, so `songTime` sounds at `hostTime`. When that point is
    /// before the file begins (a lead-in longer than the file's intro), the file starts later, at
    /// its very beginning.
    func start(fromSongTime songTime: TimeInterval,
               atHostTime hostTime: TimeInterval) -> (filePosition: TimeInterval, hostTime: TimeInterval) {
        let position = firstBeat + songTime
        guard position < 0 else { return (position, hostTime) }
        return (0, hostTime - position)
    }
}
