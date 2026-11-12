import Foundation

/// The song's own recording, played under Showtime gameplay so the first node lands on the song's
/// first beat. Scheduled on the host clock, the same timeline as the beat clock and the metronome.
@MainActor
protocol SongBackingTrack: AnyObject {
    /// Loads the recording of a song ahead of time, so starting it does not wait for the file.
    func prepare(songID: String)

    /// Plays the recording so that the given session time sounds at the given host time.
    /// Session time 0 is the first node; negative times are the lead-in before it.
    func play(fromSongTime songTime: TimeInterval, atHostTime hostTime: TimeInterval)

    /// Stops the recording at once. Safe to call when nothing plays.
    func stop()
}
