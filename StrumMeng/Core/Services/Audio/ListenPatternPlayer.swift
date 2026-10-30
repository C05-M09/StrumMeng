import AVFoundation

extension Notification.Name {
    /// A phone call or Siri took the audio; Listen pauses.
    static let listenAudioInterrupted = AVAudioSession.interruptionNotification
}

@MainActor
protocol ListenPatternPlayer: AnyObject {
    var elapsed: TimeInterval { get }
    func start(pattern: StrumPattern, bpm: Int) throws
    func pause()
    func resume()
    func stop()
}
