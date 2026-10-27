import AVFoundation

/// The iPad host clock in seconds, the same timeline AVAudioEngine schedules on. Beats, strums
/// and the Play animation all use it, so they cannot drift apart.
nonisolated enum HostClock {
    static func now() -> TimeInterval {
        AVAudioTime.seconds(forHostTime: mach_absolute_time())
    }
}
