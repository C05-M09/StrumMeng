import Foundation

/// Pattern-only Listen preview. Completion means one full loop was heard; playback may keep looping.
@MainActor
protocol SongDemoPlayer: AnyObject {
    /// Fresh subscription per preview run; replacing it must finish the previous stream.
    var events: AsyncStream<SongDemoEvent> { get }
    var elapsed: TimeInterval { get }
    func start(pattern: StrumPattern, bpm: Int) async
    func pause() async
    func resume() async
    func stop() async
}
