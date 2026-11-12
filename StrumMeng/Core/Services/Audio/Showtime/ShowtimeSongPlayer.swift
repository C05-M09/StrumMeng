import Foundation

/// Audio player for the Showtime song list character preview.
@MainActor
protocol ShowtimeSongPlayer: AnyObject {
    /// Currently playing song id, if any.
    var currentSongID: String? { get }
    /// Whether audio is actively playing.
    var isPlaying: Bool { get }

    /// Starts looping playback for the given song. If this song is already playing, does nothing.
    func playSong(id: String)
    /// Stops the currently playing song.
    func stop()
    /// Pauses playback, keeping the current position.
    func pause()
    /// Resumes playback if paused.
    func resume()
    /// Sets playback volume (0.0 ... 1.0). Clamped to VolumeConfig.
    func setVolume(_ volume: Double)
}

