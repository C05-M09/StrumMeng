import Foundation
@testable import StrumMeng

/// Records the drags the view model forwards.
final class SpyTouchStrumInput: TouchStrumInput {
    private(set) var drags: [(translation: Double, time: TimeInterval)] = []
    private(set) var endCount = 0

    func dragChanged(translation: Double, at time: TimeInterval) { drags.append((translation, time)) }
    func dragEnded() { endCount += 1 }
}
