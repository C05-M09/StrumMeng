import Foundation

@MainActor
protocol ListenPatternPlayer: AnyObject {
    var elapsed: TimeInterval { get }
    func start(pattern: StrumPattern, bpm: Int) throws
    func pause()
    func resume()
    func stop()
}
