import XCTest
@testable import StrumMeng

final class MergedStrumInputServiceTests: XCTestCase {
    func test_strumsFromEverySource_arriveOnOneStream() async {
        let touch = TouchStrumInputService()
        let controller = MockControllerLink()
        let merged = MergedStrumInputService(sources: [touch, controller])
        var iterator = merged.strums.makeAsyncIterator()
        // Let both forwarding tasks subscribe before anything is sent.
        await Task.yield()

        let fromController = PracticeFixtures.strum(at: 1, .up)
        controller.emit(fromController)
        touch.dragChanged(translation: 20, at: 2)

        var received: [StrumEvent] = []
        for _ in 0..<2 {
            if let strum = await iterator.next() { received.append(strum) }
        }
        XCTAssertTrue(received.contains(fromController))
        XCTAssertTrue(received.contains { $0.direction == .down && $0.time == 2 })
    }
}
