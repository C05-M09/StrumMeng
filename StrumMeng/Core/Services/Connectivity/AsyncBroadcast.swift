import Foundation
import os

/// Fans one source of values out to any number of AsyncStream subscribers. A plain AsyncStream
/// splits its values between consumers, but the link lives for the whole app and several screens
/// listen to it, so each one needs its own stream. Safe to use from any thread.
nonisolated final class AsyncBroadcast<Element: Sendable>: Sendable {
    private struct State {
        var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
        var latest: Element?
    }

    private let replaysLatest: Bool
    private let state: OSAllocatedUnfairLock<State>

    /// - Parameter latest: when given, each new subscriber first receives the most recent value
    ///   (use for state; leave nil for events such as strums).
    init(latest: Element? = nil) {
        replaysLatest = latest != nil
        state = OSAllocatedUnfairLock(initialState: State(latest: latest))
    }

    func stream() -> AsyncStream<Element> {
        let (stream, continuation) = AsyncStream.makeStream(of: Element.self)
        let id = UUID()
        state.withLock { state in
            if replaysLatest, let latest = state.latest { continuation.yield(latest) }
            state.continuations[id] = continuation
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLock { _ = $0.continuations.removeValue(forKey: id) }
        }
        return stream
    }

    func yield(_ element: Element) {
        let continuations = state.withLock { state in
            state.latest = element
            return Array(state.continuations.values)
        }
        for continuation in continuations { continuation.yield(element) }
    }

    /// The most recent value, if any has been sent (or given at init).
    var latest: Element? {
        state.withLock { $0.latest }
    }
}
