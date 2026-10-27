import Foundation
@testable import StrumMeng

/// Silent input. Tests deliver strums straight to the view model or engine.
final class MockStrumInputService: StrumInputService {
    var strums: AsyncStream<StrumEvent> { AsyncStream { _ in } }
}
