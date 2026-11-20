import Foundation

/// Strums from several sources as one stream, so the player can swipe on the iPad screen and on
/// the iPhone controller in the same session. Every source is already on the iPad host clock and
/// de-duplicated, so merging needs nothing more.
final class MergedStrumInputService: StrumInputService {
    private let sources: [any StrumInputService]

    init(sources: [any StrumInputService]) {
        self.sources = sources
    }

    /// A new stream per subscriber; it stops listening to the sources when the subscriber ends.
    var strums: AsyncStream<StrumEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: StrumEvent.self)
        let tasks = sources.map { source in
            let strums = source.strums
            return Task {
                for await strum in strums { continuation.yield(strum) }
            }
        }
        continuation.onTermination = { _ in
            tasks.forEach { $0.cancel() }
        }
        return stream
    }
}
