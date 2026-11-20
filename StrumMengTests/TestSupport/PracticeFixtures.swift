import Foundation
@testable import StrumMeng

enum PracticeFixtures {
    static func strum(at time: TimeInterval, _ direction: StrumDirection = .down) -> StrumEvent {
        StrumEvent(id: UUID(), direction: direction, time: time)
    }

    static func events(_ results: [BeatResult]) -> [BeatEvent] {
        results.enumerated().map { BeatEvent(stepIndex: $0.offset, result: $0.element, offsetMs: nil) }
    }
}
